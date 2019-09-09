#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'optimist'
require 'pry'

OPTS = Optimist::options do
  version "#{$0} 1.0 (c) 2019 siberas"
  opt :project, "Projectname", :type => :string
  opt :session, "Sessionname", :type => :string
  opt :chatid, "ChatId", :type => :string
end

Optimist.die :project, "Need project name" unless OPTS[:project]
Optimist.die :session, "Need session name" unless OPTS[:session]
Optimist.die :chatid, "Need the chatid" unless OPTS[:chatid]

require 'watobo'

puts Watobo::Conf::General.workspace_path

ds = Watobo::DataStore.connect(OPTS[:project], OPTS[:session])

request = nil
ds.each_chat do |c|
  next unless c.id == OPTS[:chatid].to_i
  request = c.request
  break
end

raise "chatid not found" if request.nil?

cr = Watobo::Utils::Curl.create_request(request)
puts cr
