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
# F I L E S C A N N E R
# requires workspace, project and session to save results
# requires url
#
# and optional baseline (the location where watobo chats are stored)
#
# Results/Findings are stored to
#   WORKSPACE/PROJECT/SESSION/Findings
# or additionally to OPTS[:out_dir]
#
# Example for run filescanner against VulnApp (see spec/app):
# bundle exec bin/filescanner.rb -p scan01 -s s01 -w /tmp/ -u http://127.0.0.1:9292/leaks/protected/ --database /dumpster/Projects/wordlists/lists/simple/leaky-files.txt
#
#
# WATOBO_USER_AGENT=Howdy bundle exec bin/filescanner.rb -p scan01 -s s23 -w /tmp/ -u http://127.0.0.1:9292/ --database /tmp/dummy.txt --baseline-dir spec/spec_data/filescanner_leaks/simple --scanlog-name leaky-files-01 -e ''

OPTS = Optimist::options do
  version '(c) 2021 Filescanner'
  banner <<-EOS
    Wrapper to use the FileScanner plugin directly from the command line.
  EOS

  opt :project, "Project name", :type => :string
  opt :baseline_dir, "directory of baseline chats, e.g. conversation directory of crawler-result", :type => :string
  opt :session, "Session name", :type => :string
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
  opt :database, "Filename of database or simple URI-Filename", :type => :string
  opt :scanlog_name, "name of log directory", :type => :string
  opt :evasion, "evasion extensions, multiple or comma separated", :type => :strings, :multi => true, :default => %w(HttpMethodOverride ParmExtensions HTTPVersion SlashSlash AppendSlash AuthHeader UrlExtensions UserAgent UrlParameters Cookieless HttpHeaders)
  opt :workspace, "workspace directory", :type => :string, default: '/tmp/filescanner'
  opt :config, "file with configuration settings in JSON format", :type => :string
  opt :recursively, "scan recursively", :type => :boolean, :default => true
  opt :quiet, "no unneccessary output"
  opt :run_passive_checks, "run passive checks during scan", :default => true
  opt :passive_check_filter, "filter for passive checks", type: :string, default: '.*'
  opt :rating, "set vuln rating for valid files[ 1(low) - 5 (critical) ]", type: :string, default: '0'
  opt :llm_rating, "set LLM rating for found files"
  opt :llm_url, "URL of LLM, e.g. http://ollama:11434"
  opt :llm_model, "LLM model to use for rating", type: :string, default: 'mistral-small:24b'
  opt :out_dir, "directory to store findings", type: :string
end

prefs = {}
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
findings = []
project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

# if OPTS[:baseline] is set also sets OPTS[:recursively]
# otherwise it wouldn't be usefull

if OPTS[:baseline_dir] and File.directory?(OPTS[:baseline_dir])
  prefs[:test_all_dirs] = true
  # load baseline into Watobo::Chats
  Watobo::Chats.load_marshaled(OPTS[:baseline_dir])
end

request = Watobo::Request.new OPTS[:url]



prefs[:db_file] = OPTS[:database]
# prefs[:evasion_extension] = OPTS[:evasion].split(' ').map{|e| e.strip }

prefs[:scanlog_name] = OPTS[:scanlog_name] if !!OPTS[:scanlog_name]
prefs[:rating] = OPTS[:rating]

if !!OPTS[:run_passive_checks]
  puts "+ starting passive scanner ..." if $VERBOSE
  Watobo::PassiveScanner.start
  prefs[:run_passive_checks] = true
end

unless OPTS[:quiet]
  puts "+ subscribe to Finding :new"
  Watobo::Findings.subscribe(:new) do |f|
    puts "+ [Finding]: " + f.request.url.to_s
    findings << f
  end
end

#binding.pry
#prefs[:evasions] = Watobo::Evasions.list
#prefs[:evasions] = OPTS[:evasion]
evasions = OPTS[:evasion].flatten.map{|e| e.split(',')}.flatten.map(&:strip).map(&:downcase).uniq
prefs[:evasions] = Watobo::Evasions.list.select{|e| evasions.any?(e.downcase) }

puts "+ create scanner .." if $VERBOSE
scanner = Watobo::Plugin::Filescanner.new request, prefs
scanner.subscribe(:finished) do
  puts "+ Filescanner FINISHED!"
end
scanner.run(prefs)

sleep 3

while !scanner.finished?
  print '.' if $VERBOSE
  sleep 3
end

unless OPTS[:quiet]
  findings.each do |f|
    puts "+ [Finding]: " + f.request.url.to_s
  end
end

binding.pry






