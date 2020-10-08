require 'devenv'
require 'pry'
require 'bbhunter'

puts Watobo::Conf::General.workspace_path

require 'optimist'

OPTS = Optimist::options do
  version "#{$0} (c) 2020 siberas"
  opt :project, "Projectname", :type => :string
  opt :session, "Sessionname", :type => :string
end

#Optimist.die :project, "Need project name" unless OPTS[:project]
#Optimist.die :session, "Need session name" unless OPTS[:session]

project_name = OPTS[:project]
session_name = OPTS[:session]

unless project_name
  Watobo::DataStore.projects do |p|
    puts p
  end
end


unless session_name
  Watobo::DataStore.sessions(project_name) do |s|
    puts s
  end
end

#ds = Watobo::DataStore.connect(project_name, session_name)
#puts ds.num_findings
#puts "* searching for parameters in #{ds.num_chats} chats ..."
#pnames = []
#ds.each_chat do |c|
#  next unless c.request.site =~ /rtc/
#  c.request.parameters(:url, :data, :wwwform).each do |p|
#pnames << "#{p.name} - #{p.location} - #{c.request.path}"
#    pnames << "#{p.name} - #{p.location}"
#  end
#end

project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

puts "= Active Checks ="
puts Watobo.active_checks

if nil
# Watobo Scanner Settings
  scan_prefs = Watobo::Conf::Scanner.to_h
  puts "==="
  puts "Scanner Configuration:"
  puts scan_prefs
  scan_prefs[:scanlog_name] = 'manual_scan'
#scan_prefs.update quick_scan_options

  scan_chats = []
  @chat = Watobo::Chats.to_a.select { |c| c.request.site =~ /e\-schenke/ }.first
  scan_chats.push Watobo::Chat.new(Watobo::Request.new(@chat.request), Watobo::Response.new(@chat.response), :id => @chat.id, :run_passive_checks => false)

  ac_selection = [Watobo.active_checks[5].new(project)]
  @scanner = Watobo::Scanner3.new(scan_chats, ac_selection, [], scan_prefs)

  @scanner.run

  while @scanner.status_running?
    sleep 3
  end
end
binding.pry

#
# req = Watobo::Chats.with_param('q', :url).first.request
