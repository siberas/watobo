#!/usr/bin/ruby
if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
  $: << inc_path
end

require 'watobo'

cert = {
                :hostname => 'localhost',
                :type => 'server',
                :user => 'watobo',
                :email => 'root@localhost',
              }

cert_file, key_file = Watobo::CA.create_cert cert

puts cert_file
puts key_file