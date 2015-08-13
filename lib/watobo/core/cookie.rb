# @private
module Watobo#:nodoc: all

  #Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; path=/; secure
  class Cookie < Parameter

    attr :name
    attr :value
    attr :path
    attr :secure
    attr :http_only
    
    def to_s
      "#{@name}=#{@value}"
    end    

    def initialize(prefs)
      @secure = false
      @http_only = false
      
      if prefs.respond_to? :has_key?
        @secure = prefs.has_key?(:secure) ? prefs[:secure] : false
        @http_only = prefs.has_key?(:http_only) ? prefs[:http_only] : false
        @location = :cookie
        @path = prefs[:path]
        @name = prefs[:name]
        @value = prefs[:value]
      else
       # puts "= NEW COOKIE ="
       # puts prefs
       # puts prefs.class
        chunks = prefs.split(";")
        # first chunk
        @name, @value = chunks.first.split(":").last.split("=")
        
        m = prefs.match(/path=([^;]*)/)
        @path = m.nil? ? "" : m[1].strip
        @secure = true if chunks.select{|c| c =~ /Secure/i }
        @http_only = true if chunks.select{|c| c =~ /HttpOnly/i }
      end

      #if prefs.is_a? Hash
      #  #TODO: create cookie with hash-settings
      #  else
      #  raise ArgumentError, "Need hash (:name, :value, ...) or string (Set-Cookie:...)"
      #end
    end

  end
end