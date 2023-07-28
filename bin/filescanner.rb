#!/usr/bin/env ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")) # this is the same as rubygems would do
  $: << inc_path

  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "plugins")) # this is the same as rubygems would do
  $: << inc_path
end

require 'drb/drb'
require 'devenv'

require 'optimist'


OPTS = Optimist::options do
  version '(c) 2021 Filescanner'
  banner <<-EOS
    Wrapper to use the FileScanner plugin directly from the command line.
  EOS

  opt :project, "Project name", :type => :string
  opt :session, "Session name", :type => :string
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
  opt :database, "Filename of database or simple URI-Filename", :type => :string
  opt :scanlog_name, "name of log directory", :type => :string
  opt :evasion, "evasion extensions", :type => :string, :default => '/; ?y=x.png ?debug=true'
  opt :workspace, "workspace directory", :type => :string
  opt :config, "file with additional configuration settings in JSON format", :type => :string
  opt :quiet, "no unneccessary output"
  opt :run_passive_checks, "run passive checks during scan"
  opt :passive_check_filter, "filter for passive checks", type: :string, default:  '.*'
  opt :rating, "set vuln rating for valid files[ 1(low) - 5 (critical) ]", type: :string, default: '0'

end

project_name = OPTS[:project]
session_name = OPTS[:session]

Optimist.die :url, "no url given" unless OPTS[:url]
Optimist.die :database, "no database or URI-file given" unless OPTS[:database]

# IMPORTANT!!!
# we need to set envirionment variables before we load watobo

#
# disable watobo proxy to not generate CA certificate
ENV['WATOBO_PROXY'] = 'false'

if OPTS[:workspace]
  if File.exist? OPTS[:workspace]
    ENV['WATOBO_HOME'] = OPTS[:workspace]
  else
    raise "! workspace #{OPTS[:workspace]} not found !"
  end
end

require 'watobo'
include Watobo
require 'filescanner/headless'

unless project_name
  unless OPTS[:quiet]
    puts "Need Project Name!"
    Watobo::DataStore.projects do |p|
      puts p
    end
  end
  exit
end


unless session_name
  unless OPTS[:quiet]
    puts 'Need Session Name!'
    Watobo::DataStore.sessions(project_name) do |s|
      puts s
    end
  end
  exit
end

Watobo.init_framework
project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

request = Watobo::Request.new OPTS[:url]

prefs = {}
prefs[:db_file] = OPTS[:database]
prefs[:evasion_extension] = OPTS[:evasion].split(' ').map{|e| e.strip }
prefs[:scanlog_name] = OPTS[:scanlog_name] if !!OPTS[:scanlog_name]
prefs[:rating] =OPTS[:rating]

if !!OPTS[:run_passive_checks]
  puts "+ starting passive scanner ..." if $VERBOSE
  Watobo::PassiveScanner.start
  prefs[:run_passive_checks] = true
end

unless OPTS[:quiet]
  Watobo::Findings.subscribe(:new) do |f|
    puts "+ [Finding]: " + f.request.url.to_s
  end
end

puts "+ create scanner .." if $VERBOSE
scanner = Watobo::Plugin::Filescanner.new request, prefs
scanner.run(prefs)


sleep 3

while !scanner.finished?
  print '.' if $VERBOSE
  sleep 3
end








