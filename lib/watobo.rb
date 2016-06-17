#!/usr/bin/ruby
#Encoding: UTF-8
require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts "You will need bundler to run watobo!"
  puts "please run\n gem install bundler\n bundle install\n"
  exit
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

# WORKAROUND FOR LINUX :(
dont_know_why_REQUIRE_hangs = Mechanize.new

# @private 
module Watobo#:nodoc: all #:nodoc: all

  VERSION = "0.9.23"

  def self.base_directory
    @base_directory ||= ""
    @base_directory = File.expand_path(File.join(File.dirname(__FILE__),".."))
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
