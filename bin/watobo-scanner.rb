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
require 'terminal-table'


OPTS = Optimist::options do
  version '(c) 2022 Watobo Headless Scanner'
  banner <<-EOS
Runs only the headless scanner engine of WATOBO (no proxy nor gui is started).

ENV['WATOBO_MODULES'] - String containing one ore more path-names (separated by collon). 
Caution: Using the 'module_path' option will overwrite the environment setting.


EOS

  opt :dir, "set WATOBO_HOME aka working_directory", :type => :string, :default => ENV['WATOBO_HOME']
  opt :project, "Project name", :type => :string
  opt :session, "Session name", :type => :string
  opt :filter, "Filter (Regex) for active modules <Group>:<Name>, e.g. '.Net:.Net Custom Error'", :type => :string, :default => '.*'
  opt :config, "use config file"
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
#  opt :database, "Filename with list of target URLs or simple URL", :type => :string
  opt :logname, "name of log directory", :type => :string
  opt :evasion, "enable evasion mode. this feature only applies to modules which are using evasion. When enabled it will increase the time of the scan but might get better results.", :type => :integer, :default => 1
  opt :list_modules, "lists (only) available scan modules and exit"
  opt :module_path, "path where modules are located. can also be set via 'WATOBO_MODULES' environment variable.", :type => :string
  opt :write_config, "filename to write configuration file, by given settings (config-file, filter pattern). No scan will be performed.", :type => :string
  opt :conversation_path, "path to already recorded conversation, will be loaded to perform scan", :type => :string
#  opt :module, "scan only specified module (can be used multiple times)", :type => :string, :multi => true

end

Optimist.die :url, "Need target URL" if !OPTS[:url] and !OPTS[:modules] and !OPTS[:write_config]

# set envirionment WATOBO_HOME to "forward" to watobo
ENV['WATOBO_HOME'] = OPTS[:work_dir]
ENV['WATOBO_MODULES'] = OPTS[:module_path] if OPTS[:module_path]
# set WATOBO_PROXY to false, so no proxy certificate will be generated
# It's not required when not running the interception proxy.
ENV['WATOBO_PROXY'] = 'false'

require 'watobo'

include Watobo

project_name = OPTS[:project]
session_name = OPTS[:session]

config = OPTS[:config] ? YAML.load_file(OPTS[:config]) : {}

scan_prefs = Watobo::Conf::Scanner.to_h

scan_prefs[:scanlog_name] = OPTS[:logname] if OPTS[:logname]
scan_prefs[:dns_sensor] = OPTS[:sensor] if OPTS[:sensor]
Watobo::Conf::Scanner.set scan_prefs

Watobo::ActiveModules.init

if OPTS[:write_config]
  puts "Current config:"
  puts config.to_yaml

  config[:scan_prefs] = scan_prefs unless !!config[:scan_prefs]
  config[:modules] ||= []
  config[:modules].concat Watobo::ActiveModules.select(OPTS[:filter]).map{|m| m.name }
  config[:modules].uniq!

  puts "\nFinal Configuration:"
  puts config.to_yaml

  fn = OPTS[:write_config]
  outfile = File.expand_path(fn)
  if File.directory?(outfile)
    puts "Please provide full path to file."
    exit
  end

  outdir = File.dirname(outfile)
  unless File.exist?(outdir)
    puts "Path not found!"
    exit
  end

  print "Do you want to write config to #{outfile}? [Yn]:"
  a = STDIN.gets
  a.strip!
  unless a.empty? or a =~ /^y/i
    exit
  end

  File.open(outfile,'w'){|fh| fh.puts config.to_yaml }
  puts "config has been written to #{outfile}"


  exit
end

if OPTS[:modules]
  table = Terminal::Table.new :headings => ['Class','Name']
  Watobo::ActiveModules.to_a.sort_by { |a | a.check_group  }.each do |m|
    table << [ m.check_group , m.check_name ]
  end
  puts table
  binding.pry if $DEBUG
  exit
end


if !project_name

  puts "Need Project Name!"
  Watobo::DataStore.projects do |p|
    puts p
  end
  exit
end


if !session_name
  puts 'Need Session Name!'
  Watobo::DataStore.sessions(project_name) do |s|
    puts s
  end
  exit
end

Watobo.init_framework



project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject

module_filter = OPTS[:filter] ? OPTS[:filter] : '.*'
selected_checks =  Watobo::ActiveModules.select module_filter


puts "* Running checks with following modules:"
selected_checks.each do |check|
  puts check.check_group + ' ' + check.check_name
end



puts "+ create scanner .."
puts scan_prefs

request = Watobo::Request.new OPTS[:url]
scan_chats = [ Chat.new(request, [])]

scanner = Watobo::Scanner4::Scanner.new(scan_chats, selected_checks, [], scan_prefs)
scanner.run


scanner.wait