#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")) # this is the same as rubygems would do
  $: << inc_path
end

require 'drb/drb'
require 'devenv'

require 'optimist'
require 'watobo'

require 'watobo/server'

include Watobo

OPTS=Optimist::options do
  version '(c) 2020 WATOBO DRB-Server'
  banner <<-EOS
    my banner
  EOS

  opt :workspace, "targets name", :type => :string
  opt :port, "port of drb listener port", :default => 4444

end

#Optimist::die :targets, "targets name must be given" unless OPTS[:targets]

port = OPTS[:port]

server = Watobo::Server.new('/tmp/gaga')

server.crawl 'https://www.siberas.de'
DRb.start_service("druby://127.0.0.1:#{port}", worker)


puts "Worker READY!"
DRb.thread.join