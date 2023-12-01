module Watobo
  module Headless
    class Spider
      class Form

        attr :src, :method, :action, :form_class, :button

        def fingerprint
          s = [ src, method, action, ( button || '') ]
          Digest::MD5.hexdigest s.join('|')
        end

        # needed for stats output
        def to_s
          "[Form] #{method || 'POST'} #{action}"
        end


        # @param url [String]
        # @param attributes [Hash] of form attributes
        # @param button [String|nil] css_selector of button, css is created with form_collection.css(element)
        def initialize(url, attributes, button=nil)
          @src = url
          @method = attributes.fetch('method')
          @action = attributes.fetch('action')
          @form_class = attributes.fetch('class')
          @button = button
        end
      end
    end
  end
end