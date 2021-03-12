#!/usr/bin/ruby
#Encoding: UTF-8
require 'rubygems'

$SAFE = 0

# TODO: use a different environment variable to disable bundler on load
# usefull if you want to use your own gems for private plugins
#
unless ENV['DEV_ENV']
  begin
    require 'bundler/setup'
  rescue LoadError
    puts "You will need bundler to run watobo!"
    puts "please run\n gem install bundler\n bundle install\n"
    exit
  end
end


require 'yaml'
require 'json'
require 'thread'
require 'socket'
require 'timeout'
require 'openssl'
require 'optparse'
require 'digest/md5'
require 'stringio'
require 'zlib'
require 'base64'
require 'cgi'
require 'uri'
require 'pathname'
#require 'rubyntlm'
#require 'net/ntlm'
#require 'httpi'
require 'drb'
require 'nokogiri'
require 'stringio'
require 'mechanize'
require 'jwt'
require 'ostruct'
require 'erb'

print '+ looking for DEV_ENV environment variable ...'
if ENV['DEV_ENV']
  print "[OK]\n"
  puts '+ loading devgems ...'
  begin
    require 'devenv'
    devgems =  File.join( File.expand_path(ENV['HOME']), '.watobo', 'devgems.rb')
    puts "+ loading devgem file #{devgems}"
    #load devgems
    require_relative devgems
  rescue LoadError => bang
    puts '* something went wrong while initialising the development environment.'
    puts bang
    puts bang.backtrace
  end
else
  print "[N/A]\n"
end


require 'watobo/constants'
require 'watobo/utils'
require 'watobo/mixins'
require 'watobo/config'
require 'watobo/defaults'
require 'watobo/http'
require 'watobo/core'
require 'watobo/externals'
require 'watobo/adapters'
require 'watobo/framework'
require 'watobo/parser'
require 'watobo/interceptor'
require 'watobo/sockets'

require 'watobo/transformers/multipart'


# WORKAROUND FOR LINUX :(
#dont_know_why_REQUIRE_hangs = Mechanize.new

# @private 
module Watobo #:nodoc: all #:nodoc: all

  VERSION = "1.1.0pre"

  def self.base_directory
    @base_directory ||= ""
    @base_directory = File.expand_path(File.join(File.dirname(__FILE__), ".."))
  end

  def self.plugin_path
    @plugin_directory ||= ""
    @plugin_directory = File.join(base_directory, "plugins")
  end

  def self.active_module_path
    @active_module_path = ""
    @active_path = File.join(base_directory, "modules", "active")
  end

  def self.passive_module_path
    @passive_module_path = ""
    @passive_path = File.join(base_directory, "modules", "passive")
  end

  def self.version
    Watobo::VERSION
  end


end

Watobo.init_framework

require 'watobo/ca'
