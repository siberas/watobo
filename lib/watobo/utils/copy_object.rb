# @private 
module Watobo#:nodoc: all
  module Utils
    def Utils.copyObject(object)
      copy = Marshal.load(Marshal.dump(object))
        return copy
    end
  end
end
