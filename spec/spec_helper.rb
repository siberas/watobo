#!/usr/bin/ruby
# rspec --format documentation ./spec/response_spec.rb

ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'

require 'devenv'
require 'watobo'
require 'pry'

require_relative './app/app'

RSpec.configure do |config|
  config.before(:suite) do
    if ENV['RACK_ENV'] == 'development'
      @app = VulnApp.new.freeze
      Thread.new do
        @server = Rack::Server.start(app: @app, Port: 6666, Host: 'localhost')
      end
      while true
        begin
          response = Net::HTTP.get_response(URI('http://localhost:6666/'))
          break if response.is_a?(Net::HTTPSuccess)
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        end
        sleep 0.1
      end
    end
  end

  config.after(:suite) do
    if ENV['RACK_ENV'] == 'development'
      @server.stop if @server
    end
  end
end