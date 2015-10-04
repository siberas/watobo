# @private 
module Watobo#:nodoc: all
  module Utils
    utils_path = File.expand_path(File.join(File.dirname(__FILE__), "utils"))
    #puts "* loading utils #{utils_path}"
    Dir.glob("#{utils_path}/*.rb").each do |cf|
      puts "+ #{File.basename(cf)}" if $DEBUG
      require File.join("watobo","utils", File.basename(cf))

    end
  end
end