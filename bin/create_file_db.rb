#!/usr/bin/ruby
# creates a db file for filefinder plugin
# it searches the given path for xml files containing action path definitions, e.g. struts
inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'optimist'
require 'watobo'

OPTS = Optimist::options do
  version "#{$0} 1.0 (c) 2019 siberas"
  opt :dirname, "Name of directory", :type => :string
  opt :output, "Output file", :type => :string, :default => ''
end

Optimist.die :dirname, "Need a directory name" unless OPTS[:dirname]

extensions = %w( do jsp go )

folder = OPTS[:dirname]
out_file = OPTS[:output]

action_paths = []
Dir.glob("#{folder}/*.xml").each do |file|
  doc = Nokogiri::XML(File.read(file))
  actions = doc.css("//action")
  actions.each do |action|
    extensions.each do |ext|
      action_paths << (action[:path].gsub(/^\//, '') + ".#{ext}")
    end
  end
end

unless out_file.empty?
  action_paths.uniq!
  File.open(out_file, "w") do |fh|
    fh.puts action_paths
  end
  puts "+ written #{action_paths.length} entries to #{out_file}"
else
  puts "+ Found #{action_paths.length} entries"
end


