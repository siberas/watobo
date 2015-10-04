# @private 
module Watobo#:nodoc: all
  module Mixins
    mixins_path = File.expand_path(File.join(File.dirname(__FILE__), "mixins"))
  # puts "* loading mixins #{mixins_path}"
    Dir.glob("#{mixins_path}/*.rb").each do |cf|
      puts "+ #{File.basename(cf)}" if $DEBUG
      require File.join("watobo","mixins", File.basename(cf))

    end
  end
end