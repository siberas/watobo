# @private 
module Watobo#:nodoc: all
  module CheckInfoMixin
    module InfoMethods
      def check_name
       
        #puts self.methods.sort
        info = instance_variable_get("@info")
        return nil if info.nil?
        return info[:check_name]
      end
      
      def check_group
        info = instance_variable_get("@info")
        return nil if info.nil?
        return info[:check_group]
      end

    end

    extend InfoMethods

    def self.included( other )
      other.extend InfoMethods
    end
  #:name => "#{check.info[:check_group]}|#{check.info[:check_name]}",

  end
end