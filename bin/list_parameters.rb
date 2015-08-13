#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end
require 'trollop'

OPTS=Trollop::options do
  version "#{$0} 0.1 (c) 2014 siberas"
  opt :project, "Projectname", :type => :string
  opt :session, "Sessionname", :type => :string
  opt :url, "URL pattern", :type => :string, :default => "*"
end

Trollop.die :project, "Need project name" unless OPTS[:project]
Trollop.die :session, "Need session name" unless OPTS[:session]

require 'watobo'

puts Watobo::Conf::General.workspace_path

ds = Watobo::DataStore.connect(OPTS[:project], OPTS[:session])
#puts ds.num_findings
puts "* searching for parameters in #{ds.num_chats} chats ..."
pnames = []
ds.each_chat do |c|
  next unless c.request.site =~ /#{OPTS[:url]}/
  c.request.parameters(:url, :data, :wwwform).each do |p|
    #pnames << "#{p.name} - #{p.location} - #{c.request.path}"
    pnames << "#{p.name} - #{p.location}"
  end
end

puts pnames.uniq
