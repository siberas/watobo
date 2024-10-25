module Watobo
  module Headless
    class Spider
      class Click

        attr :css, :src

        def to_s
          @css
        end

        def fingerprint(opts = {})
          o = { :clear_values => true }
          o.update opts

          Digest::MD5.hexdigest @css
        end

        def cleanup_uri(obj)
          uri = nil
          uri = obj.uri if obj.respond_to? :uri
          uri = URI.parse(obj) if obj.is_a? String
          uri = obj if obj.is_a? URI::HTTP
          uri
        end

        # @param src [String] url of click element
        # @param element [Webdriver::Element] to be clicked
        def initialize(src, element)
          @src = src

          tag_name = element.tag_name
          id = element.attribute('id')
          classes = element.attribute('class')&.split(' ') || []

          # Build the CSS selector
          selector_parts = [tag_name]
          selector_parts << "##{id}" unless id.empty?
          classes.each { |class_name| selector_parts << ".#{class_name}" }
          @css = selector_parts.join

        end
      end
    end
  end
end