# @private 
module Watobo#:nodoc: all
  module Utils
    def Utils.copyObject(object)
      # copy = secure_eval(YAML.load(YAML.dump(object.inspect)))
      copy = Marshal.load(Marshal.dump(object))
        return copy
    end
  end
end
