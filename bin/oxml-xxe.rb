#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end

require 'base64'
require 'openssl'
require 'optimist'
require 'pry'
require 'nokogiri'
require 'fileutils'

OPTS = Optimist::options do
  version "#{$0} 1.0 (c) 2022 siberas"
  opt :path, " path to extracted doc/xls files", :type => :string
  opt :url, "will be set as system_id for DTD location", :type => :string

end


Optimist::die :path, "need pathname to oxml files" unless OPTS[:path]
Optimist::die :url, "need url, e.g. http://my.system.com/bla.dtd" unless OPTS[:url]

path = OPTS[:path]
Dir.glob("#{path}/**/*.xml") do |f|
  FileUtils.cp f, "#{f}.orig"
  name = nil
  external_id = nil
  system_id = nil

  puts "Inject DTD location #{f}"
  xml = Nokogiri::XML(IO.binread(f))
  # preserve subset values if available
  unless xml.document.internal_subset.nil?
    name = xml.document.internal_subset.name
    exernal_id = xml.document.internal_subset.external_id
    # system_id = xml.document.internal_subset.system_id
    xml.document.internal_subset.remove
  end

  name = name.nil? ? 'root' : name
  exernal_id = exernal_id.nil? ? "-//A/B/EN" : exernal_id
  system_id = OPTS[:url]

  xml.document.create_internal_subset(name, exernal_id, system_id)

  IO.binwrite(f, xml.to_xml)
end

