# @private 
module Watobo#:nodoc: all

  module Plugin
    def self.each
      constants.each do |c|
        yield c if block_given?
      end
    end
  end

end
