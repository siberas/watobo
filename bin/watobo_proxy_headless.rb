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


OPTS=Optimist::options do
  version '(c) 2021 Filescanner'
  banner <<-EOS
    Wrapper to use the watobo's proxy directly from the command line.
  EOS

  opt :home_path, "set WATOBO_HOME environment", :type => :string, :default=> ENV['WATOBO_HOME']
  opt :project, "Project name", :type => :string
  opt :session, "Session name", :type => :string
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
  opt :database, "Filename of database or simple URI-Filename", :type => :string
  opt :logname, "name of log directory", :type => :string
  opt :evasion, "evasion mode. 0 - None, 1 - string append", :type => :integer, :default => 1

end

ENV['WATOBO_HOME'] = OPTS[:home_path]

require 'watobo'

include Watobo


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

Watobo::PassiveScanner.start

Watobo::Interceptor.start

binding.pry