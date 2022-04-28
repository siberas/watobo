# @private 
module Watobo#:nodoc: all
  class Proxy < OpenStruct
      include Watobo::Constants
      

#      def method_missing(name, *args, &block)
#          # puts "* instance method missing (#{name})"
#          if @settings.has_key? name.to_sym
#            return @settings[name.to_sym]
#          else
#            super
#          end
#        end
        
      def to_yaml
        self.to_h.to_yaml
      end


      def has_login?
       # puts @settings.to_yaml
        return unless !!self[:auth_type]
        return false if self[:auth_type] == AUTH_TYPE_NONE
        return true
      end

      def initialize(prefs)
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :host
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :port
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :name
        
        defaults = {
          :auth_type => AUTH_TYPE_NONE, 
          :username => '', 
          :password => '',
          :domain => '',
          :workstation => ''}
        
        defaults.update prefs
        super defaults

      end
    end
end