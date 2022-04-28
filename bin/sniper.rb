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
require 'fileutils'


OPTS = Optimist::options do
  version '(c) 2021 Sniper'
  banner <<-EOS
    Wrapper to use the FileScanner plugin directly from the command line.
  EOS

  opt :project, "Project name", :type => :string, :default => 'sniper'
  opt :session, "Session name", :type => :string, :default => 's'+ Time.now.to_i.to_s
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
  opt :logname, "name of log directory", :type => :string, :default => "sniper_#{Time.now.to_i}"
  opt :workspace, "workspace directory", :type => :string
  opt :run_passive_checks, "run passive checks during scan"
  opt :check, "pattern of checks to perform", :type => :string, :default => '.*'
  opt :list, "List available check modules"
  opt :sensor, "sensor system <host>:<port>, used as DNS ", :type => :string

end

if OPTS[:list]
  require 'watobo'
  Watobo::ActiveModules.init

  Watobo::ActiveModules.to_a.each do |m|
    puts m.check_group + ' : ' + m.check_name
  end
  exit
end
project_name = OPTS[:project]
session_name = OPTS[:session]

Optimist.die :url, "no url given" unless OPTS[:url]

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
else
  puts "! no working directory given. Using /tmp/watobo !"
  ENV['WATOBO_HOME'] = '/tmp/watobo'
  FileUtils.mkdir_p ENV['WATOBO_HOME']

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


selected_checks =  Watobo::ActiveModules.to_a.select do |m|
   m.check_group + ' : ' + m.check_name =~ /#{OPTS[:check]}/i
end

puts "* Running checks with following modules:"
selected_checks.each do |check|
  puts check.check_group + ' ' + check.check_name
end

prefs = Watobo::Conf::Scanner.to_h

prefs[:scanlog_name] = OPTS[:logname] if OPTS[:logname]
prefs[:dns_sensor] = OPTS[:sensor] if OPTS[:sensor]
Watobo::Conf::Scanner.set prefs

puts "+ create scanner .."
puts prefs

request = Watobo::Request.new OPTS[:url]
scan_chats = [ Chat.new(request, [])]

scanner = Watobo::Scanner3.new(scan_chats, selected_checks, [], prefs)
scanner.run(prefs)


sleep 3

while !scanner.finished?
  puts "wait for finish" if $VERBOSE
  sleep 3
end








