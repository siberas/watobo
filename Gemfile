source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'rspec'
  gem 'sinatra'
  gem 'rspecproxies'
  gem 'rackup'
end

group :private_gems do
private_gems_file = File.join( ENV['HOME'], '.watobo/Gemfile.private')
eval_gemfile private_gems_file if File.exist?(private_gems_file)
end

gem 'drb'
gem 'nokogiri'
gem 'xmlrpc'
gem 'rubyntlm'
gem 'mechanize'
gem 'fxruby', '1.6.50'
gem 'jwt'
gem 'jose'
gem 'nfqueue', '1.0.4' if RUBY_PLATFORM =~ /linux/
# gem 'net-http-pipeline', '1.0.1' if RUBY_PLATFORM =~ /linux/
gem 'selenium-webdriver'

gem 'optimist'
gem 'uri'
# gem 'kmeans-clusterer'
gem 'damerau-levenshtein'
gem 'openapi3_parser'

path = ENV['DEV_ENV']
path = path || ENV['BBH_WORKSPACE']
path = path || ENV['HOME']
#path = path || ENV['HOME']
# gem 'devenv', '= 0.8', :path => File.join(path, 'devenv')

#if ENV['DEV_ENV'] && File.exist?(ENV['DEV_ENV'])
#  gem 'devenv', '= 0.8', :path => File.join(ENV['DEV_ENV'], 'devenv'), group: [:development]
#end