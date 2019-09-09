#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib")) # this is the same as rubygems would do
$: << inc_path
end

puts "#############################################################"
puts
puts "     W A T O B O - THE Web Application Toolbox"

puts "     brought to you by siberas http://www.siberas.de"
puts
puts "#############################################################"


require 'pry'

require 'watobo'
require 'watobo/gui'

puts Watobo::Gui.info

puts ">> Starting GUI ..."
Watobo::Gui.start
