source 'https://rubygems.org'

group :development do
  gem 'pry'
  gem 'rspec'
  gem 'sinatra'
  gem 'rspecproxies'
end

gem 'nokogiri'
gem 'xmlrpc'
gem 'rubyntlm'
gem 'mechanize'
gem 'fxruby', '1.6.48'
gem 'jwt'
gem 'nfqueue', '1.0.4' if RUBY_PLATFORM =~ /linux/
# gem 'net-http-pipeline', '1.0.1' if RUBY_PLATFORM =~ /linux/
gem 'selenium-webdriver'

gem 'optimist'
gem 'uri'
gem 'kmeans-clusterer'
gem 'damerau-levenshtein'
gem 'openapi3_parser'

path = ENV['DEV_ENV']
path = path || ENV['BBH_WORKSPACE']
path = path || ENV['HOME']
#path = path || ENV['HOME']
gem 'devenv', '= 0.8', :path => File.join(path, 'devenv')

#if ENV['DEV_ENV'] && File.exist?(ENV['DEV_ENV'])
#  gem 'devenv', '= 0.8', :path => File.join(ENV['DEV_ENV'], 'devenv'), group: [:development]
#end

# load private gems
private_gems = File.join( ENV['HOME'], '.watobo/Gemfile.private')
if File.exist?( private_gems )
  puts "Loading private Gemfile ..."
  eval_gemfile File.expand_path(private_gems)
else
  puts "No private Gemfile found"
end
