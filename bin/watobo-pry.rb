require 'devenv'
require 'pry'
require 'watobo'

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
  puts "Need Project Name!"
  Watobo::DataStore.projects do |p|
    puts p
  end
  exit
end


unless session_name
  puts 'Need Session Name!'
  Watobo::DataStore.sessions(project_name) do |s|
    puts s
  end
  exit
end


project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

puts "= Active Checks ="
puts Watobo.active_checks

binding.pry

#
# req = Watobo::Chats.with_param('q', :url).first.request
