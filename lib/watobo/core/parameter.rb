# @private 
module Watobo #:nodoc: all
=begin 
  
 possible locations
 - url
 - header
 - cookie
 - data (body)
 - multipart

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

    # @returns value type [Const] valid values Bool, String, Hash, Array
    def type
      @prefs[:type]
    end

    # determins if parameter is of type value (string or integer)
    # returns false if parameter is a container (hash or array)
    def is_value?
      t = @prefs[:type]
      return true if t.nil?
      return true if t.upcase.to_sym == :STRING
      return true if t.upcase.to_sym == :INTEGER
      #return false if t.upcase.to_sym == :HASH
      #return false if t.upcase.to_sym == :ARRAY
      false
    end

    def to_s
      "#{name}=#{value}"
    end

    # @param prefs [Hash]
    # 3 settings are required:
    # - :location
    # - :name
    # - :value
    def initialize(prefs)
      raise ":location is missing" unless prefs.has_key?(:location)
      raise ":name is missing" unless prefs.has_key?(:name)
      raise ":value is missing" unless prefs.has_key?(:value)

      @prefs = prefs
    end

    def copy
      # Don't copy with
      #   Parameter.new(self.to_h)
      # because we will loose Parameter specific methods, needed for internal parsing
      # TODO:
      # Alternative might be to use OpenStruct instead??
      #
      # For now we use Marshalling
      Marshal.load(Marshal.dump(self))
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
    def id
      @prefs[:id]
    end

    def initialize(prefs)
      prefs[:location] = :json
      super prefs
    end
  end

  class HeaderParameter < Parameter
    def id
      @prefs[:id]
    end

    def initialize(prefs)
      prefs[:location] = :header
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

  class MultipartParameter < Parameter

    def sub_name
      @prefs[:sub_name]
    end

    def index
      @prefs[:index]
    end

    def initialize(prefs)
      prefs[:location] = :multipart
      super prefs
    end
  end
end