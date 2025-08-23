require 'devenv'
require 'sinatra'
require 'watobo'

require_relative './app'

# Example
# RACK_ENV=development bundle exec rackup

#set :bind, '192.168.122.1'
#set :server, :puma

#require 'puma'
#run Puma::Server.new(BBhunter::App).app
#$DEBUG = ENV['BBH_DEBUG_LEVEL'].to_s.match?(/debug/i)
run VulnApp