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
  version '(c) 2021 Scanner'
  banner <<-EOS
    Runs only the headless scanner engine of WATOBO (no proxy nor gui is started).
  EOS

  opt :home_path, "set WATOBO_HOME environment", :type => :string, :default => ENV['WATOBO_HOME']
  opt :project, "Project name", :type => :string
  opt :session, "Session name", :type => :string
  opt :create, "creates automatically project and session names by given url."
  opt :url, "URL, e.g. https://www.somesite.org/xxx", :type => :string
#  opt :database, "Filename with list of target URLs or simple URL", :type => :string
  opt :logname, "name of log directory", :type => :string
  opt :evasion, "enable evasion mode. this feature only applies to modules which are using evasion. When enabled it will increase the time of the scan but might get better results.", :type => :integer, :default => 1
  opt :modules, "lists currently available scan modules"
  opt :module_path, "path where modules are located. can also be set via 'WATOBO_MODULES' environment variable.", :type => :string
  opt :module, "scan only specified module (can be used multiple times)", :type => :string, :multi => true

end

Optimist.die :url, "Need target URL" if !OPTS[:url] and !OPTS[:modules]

# set envirionment WATOBO_HOME to "forward" to watobo
ENV['WATOBO_HOME'] = OPTS[:home_path]
# set WATOBO_PROXY to false, so no proxy certificate will be generated - it's not required when not running the interception proxy.
ENV['WATOBO_PROXY'] = 'false'

require 'watobo'

include Watobo

create_names = OPTS[:create]
project_name = OPTS[:project]
session_name = OPTS[:session]

if !project_name and !create_names

  puts "Need Project Name! Or use --create ."
  Watobo::DataStore.projects do |p|
    puts p
  end
  exit
end


if !session_name and !create_names
  puts 'Need Session Name! Or use --create .'
  Watobo::DataStore.sessions(project_name) do |s|
    puts s
  end
  exit
end

Watobo.init_framework
Watobo::ActiveModules.init

if OPTS[:modules]
  table = Terminal::Table.new :headings => ['Class','Name']
  Watobo::ActiveModules.to_a.sort_by { |a | a.check_group  }.each do |m|
    puts m.check_group + ' : ' + m.check_name
    table << [ m.check_group , m.check_name ]
  end
  puts table
  exit
end

binding.pry

project = Watobo.create_project project_name: project_name, session_name: session_name
project.setupProject


