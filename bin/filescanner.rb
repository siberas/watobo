#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")) # this is the same as rubygems would do
  $: << inc_path

  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "plugins")) # this is the same as rubygems would do
  $: << inc_path
end

require 'drb/drb'
require 'devenv'

require 'optimist'
require 'watobo'

require 'filescanner/headless'


include Watobo

OPTS=Optimist::options do
  version '(c) 2021 Filescanner'
  banner <<-EOS
    Wrapper to use the FileScanner plugin directly from the command line.
  EOS

  opt :project, "Project name", :type => :string
  opt :session, "Session name", :type => :string
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
  opt :database, "Filename of database or simple URI-Filename", :type => :string
  opt :logname, "name of log directory", :type => :string
  opt :evasion, "evasion mode. 0 - None, 1 - string append", :type => :integer, :default => 1

end

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

Watobo.init_framework
project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

#puts "* starting passive scanner"
#Watobo::PassiveScanner.start

#puts "* starting interceptor"
#Watobo::Interceptor.start

request = Watobo::Request.new OPTS[:url]
prefs = {}
prefs[:db_file] = OPTS[:database]
prefs[:evasion_level] = OPTS[:evasion]
prefs[:scanlog_name] = OPTS[:logname] if !!OPTS[:logname]

scanner = Watobo::Plugin::Filescanner.new request, prefs
scanner.run(prefs)

while !scanner.running?
  puts 'wait for start ...'
  sleep 3
end

while !scanner.finished?
  puts "wait for finish"
  sleep 3
end








