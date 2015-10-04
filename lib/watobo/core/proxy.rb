# @private 
module Watobo#:nodoc: all
  class Proxy
      include Watobo::Constants
      
      attr :login
      
      def method_missing(name, *args, &block)
          # puts "* instance method missing (#{name})"
          if @settings.has_key? name.to_sym
            return @settings[name.to_sym]
          else
            super
          end
        end
        
      def to_yaml
        @settings.to_yaml
      end


      def has_login?
       # puts @settings.to_yaml
        return false if @settings[:auth_type] == AUTH_TYPE_NONE
        return true
      end

      def initialize(prefs)
        @login = nil
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :host
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :port
        raise ArgumentError, "Proxy needs host, port and name" unless prefs.has_key? :name
        
        @settings = { 
          :auth_type => AUTH_TYPE_NONE, 
          :username => '', 
          :password => '',
          :domain => '',
          :workstation => ''}
        
        @settings.update prefs

      end
    end
end