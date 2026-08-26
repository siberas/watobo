#!/usr/bin/ruby
# rspec --format documentation ./spec/response_spec.rb

require 'watobo'
require 'bundler/setup'
Bundler.require(:default, :development)

require_relative './app/app'

RSpec.configure do |config|
  config.before(:suite) do
    @app = VulnApp.new.freeze

    Thread.new do
      @server = Rackup::Server.start(app: @app, Port: 6666, Host: 'localhost')
    end
    loop do
      begin
        response = Net::HTTP.get_response(URI('http://localhost:6666/'))
        break if response.is_a?(Net::HTTPSuccess)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
      end
      sleep 0.1
    end
  end

  config.after(:suite) do
    @server.stop if @server
  end
end
