# @private
module Watobo #:nodoc: all

  #Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; path=/; secure
  class Cookie < Parameter

#    attr :name
#    attr :value
#    attr :path
#    attr :secure
#    attr :http_only

    def to_s
      "#{name}=#{value}"
    end

    def initialize(prefs)
      @secure = false
      @http_only = false
      #c_prefs = nil

      if prefs.respond_to? :has_key?
        @secure = prefs.has_key?(:secure) ? prefs[:secure] : false
        @http_only = prefs.has_key?(:http_only) ? prefs[:http_only] : false
        @location = :cookie
        @path = prefs[:path]
        @name = prefs[:name]
        @value = prefs[:value]

        c_prefs = prefs
      else
        # remove 'set-cookie:'
        prefs.strip!
        prefs.gsub!(/^(set-)?cookie(2)?:/i, '')
        prefs.strip!

        chunks = prefs.split(";")
        # only first chunk holds name and value of cookie
        name, value = chunks.first.split("=")
        value = '' if value.nil?

        c_prefs = {
            name: name.strip,
                   value: value.strip
        }

        m = prefs.match(/path=([^;]*)/)
        c_prefs[:path] = m.nil? ? "" : m[1].strip
        c_prefs[:secure] = chunks.select { |c| c =~ /Secure/i }.length > 0
        c_prefs[:http_only] = chunks.select { |c| c =~ /HttpOnly/i }.length > 0
      end

      c_prefs[:location] = :cookie
      super c_prefs
    end

  end
end