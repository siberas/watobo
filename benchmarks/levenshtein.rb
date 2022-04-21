#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'optimist'

OPTS = Optimist::options do
  version "#{$0} 0.1 (c) 2014 siberas"
  opt :path, "Path to chat files (.mrs)", :type => :string
  opt :url, "URL pattern", :type => :string, :default => "*"
end

Optimist.die :path, "Need path to chat files" unless OPTS[:path]


require 'watobo'
require 'pry'
require "damerau-levenshtein"
require 'benchmark'
require 'watobo/ml'



dl = DamerauLevenshtein

km = nil

Benchmark.bm do |x|

  x.report('load chats') {
  Watobo::Chats.load_marshaled OPTS[:path]
  }
  chats = Watobo::Chats.to_a
  puts "Loaded #{chats.length} chats"

  puts
  x.report('Init Kmeans'){
  chats = Watobo::Chats.to_a
  km = Watobo::Ml::KmeansChats.new(chats)
  }
  puts km.metrics.first.length

  puts
  x.report('Run Kmeans'){
  km.run
  }

  x.report('sequential: ') {
    km.clusters.each do |cluster|
      puts "--- Cluster ID: #{cluster.id}"
      chats = km.chats_of_cluster(cluster.id)
      puts "#chats: #{chats.length}"
      baseline = chats.first.response.body.to_s
      chats.each do |chat|
        target = chat.response.body.to_s
        dist = dl.distance baseline, target
        puts "Dist: #{dist} (#{baseline.length}/#{target.length})"
      end
    end
  }


end

binding.pry
