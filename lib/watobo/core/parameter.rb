# @private 
module Watobo #:nodoc: all
=begin 
  
 possible locations
 - url
 - header
 - cookie
 - data (body)

=end
  class Parameter
    def location
      @prefs[:location]
    end

    def name
      @prefs[:name]
    end

    def value
      @prefs[:value]
    end

    def value=(v)
      @prefs[:value] = v
    end

    def to_h
      @prefs.clone
    end

    def to_s
      "#{name}=#{value}"
    end

    def initialize(prefs)
      raise ":location is missing" unless prefs.has_key?(:location)
      raise ":name is missing" unless prefs.has_key?(:name)

      @prefs = prefs
    end

    def copy
      Parameter.new(self.to_h)
    end

    def method_missing(name, *args, &block)
      m = name.to_sym
      super unless @prefs.has_key?(m)
      return @prefs[m]
    end
  end

  class WWWFormParameter < Parameter
    def initialize(prefs)
      prefs[:location] = :data
      super prefs
    end
  end


  class UrlParameter < Parameter
    def initialize(prefs)
      prefs[:location] = :url
      super prefs
    end
  end

  class CookieParameter < Parameter
    def initialize(prefs)
      prefs[:location] = :cookie
      super prefs
    end
  end

  class JSONParameter < Parameter
    def initialize(prefs)
      prefs[:location] = :json
      super prefs
    end
  end

  class XmlParameter < Parameter
    def initialize(prefs)
      prefs[:location] = :xml
      super prefs
      # @parent = prefs.has_key?(:parent) ? prefs[:parent] : ""
      # @namespace = prefs.has_key?(:namespace) ? prefs[:namespace] : nil
    end
  end
end