#!/usr/bin/env ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")) # this is the same as rubygems would do
  $: << inc_path
end

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)
require 'bundler/setup'

require 'optimist'

OPTS = Optimist::options do
  version '(c) 2022 Watobo Sp1dR'
  banner <<-EOS


EOS

  opt :url,  "URL, e.g. https://www.somesite.org/xxx", :type => :string
  #  opt :watobo_home, "set WATOBO_HOME aka working_directory", :type => :string, :default => ENV['WATOBO_HOME']
  opt :proxy, "Proxy (host:port)", :type => :string
  opt :headless, "headless mode"
  opt :screenshot, "headless mode"
  opt :chrome_bundle_path, "set chrome driver_path", :type => :string, :default =>'/usr/share/chrome-linux'
  # TODO: num_browser raise crashes if > 1
  #  opt :num_browsers, "number of browser instances", :type => :integer, :default => 1
  opt :max_duration, "maximum duration in seconds", :type => :integer, :default => 3600
  opt :max_visits, "maximum number of total pages visited", :type => :integer, :default => 200
end

Optimist.die :url, "Need URL" unless OPTS[:url]


require 'watobo/headless'

require 'pry'
require 'uri'


prefs = {
    proxy: OPTS[:proxy],
    headless: OPTS[:headless],
    screenshot: OPTS[:screenshot],
    num_browsers: OPTS[:num_browsers],
    max_duration: OPTS[:max_duration],
    max_visits: OPTS[:max_visits]
}


spider = Watobo::Headless::Spider.new OPTS

spider.run OPTS[:url]

spider.wait

spider.print_stats
