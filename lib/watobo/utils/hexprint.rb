# @private 
module Watobo#:nodoc: all
  module Utils
    def self.hexprint(data)
      data.length.times do |i|
        print "%02X" % data[i].ord
        puts if data[i] == "\n"
      end
    end
  end
end