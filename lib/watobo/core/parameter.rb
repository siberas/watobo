# @private 
module Watobo#:nodoc: all
=begin 
  
 possible locations
 - url
 - header
 - cookie
 - data (body)

=end
  class Parameter
    attr :location
    attr :name
    attr_accessor :value
    
    def initialize(prefs)
      @location = nil
      @name = prefs[:name]
      @value = prefs[:value]
      @prefs = prefs      
    end
  end
  
  class WWWFormParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :data
    end
  end
  
  
  class UrlParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :url
    end
  end
  
  class CookieParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :cookie
    end
  end
  
  class JSONParameter < Parameter
    def initialize(prefs)
      super prefs
      @location = :json
    end
  end
  
  class XmlParameter < Parameter
    attr :parent
    attr :namespace
    def initialize(prefs)
      super prefs
      @location = :xml
      @parent = prefs.has_key?(:parent) ? prefs[:parent] : ""
      @namespace = prefs.has_key?(:namespace) ? prefs[:namespace] : nil
    end
  end
end