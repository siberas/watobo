if ENV['RACK_ENV'] == 'development'
  require 'sinatra/base'
  require_relative './vuln_modules/file_leaks'

  module Middleware
    def self.registered(app)
      app.use Rack::Session::Cookie,
              :key => 'WATOBO_RSPEC',
              :expire_after => (60 * 60 * 24 * 365),
              :secret => 'lasjkflkdslfjl'
    end
  end

  class VulnApp < Sinatra::Base
    register Middleware

    get '/' do
      # without session, no cookie will be set
      session[:foo] = :howdy
      "Hello WATOBO"
    end

    get '/foo' do
      session[:foo] || 'unknown'
    end
  end
end