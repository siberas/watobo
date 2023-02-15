module Watobo
  module Headless
    class Spider
      class Form

        attr :src, :attributes

        def fingerprint
          s = [ src, attributes.method, attributes.action]
          Digest::MD5.hexdigest s.join('|')
        end

        # needed for stats output
        def to_s
          "[Form] #{attributes.method || 'POST'} #{attributes.action}"
        end

        def initialize(url, attributes)
          @src = url
          @attributes = OpenStruct.new attributes
        end
      end
    end
  end
end