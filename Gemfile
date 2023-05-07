source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'rspec'
  gem 'sinatra'
end

gem 'nokogiri'
gem 'xmlrpc'

gem 'mechanize'
gem 'fxruby', '1.6.45'
gem 'jwt'
gem 'nfqueue', '1.0.4' if RUBY_PLATFORM =~ /linux/
#gem 'net-http-pipeline', '1.0.1' if RUBY_PLATFORM =~ /linux/
gem 'selenium-webdriver'
gem 'xmlrpc'

gem 'optimist'
gem 'uri'
gem 'kmeans-clusterer'
gem 'damerau-levenshtein'

if ENV['DEV_ENV'] && File.exist?(ENV['DEV_ENV'])
  gem 'devenv', '= 0.8', :path => File.join(ENV['DEV_ENV'], 'devenv'), group: [:development]
end
