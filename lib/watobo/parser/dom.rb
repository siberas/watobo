module Watobo
  module Parser
    module HTML
      class Dom

        def scripts

          script_tags = html.css('script')
          script_tags.each do |stag|
            next if stag.content.empty?
          end
        end


        # @param html (Nokogiri::HTML)
        def initialize(html)

        end


        def self.create(html_code)
          begin
            html = Nokogiri::HTML(html_code)
            return html
          rescue => bang
            puts bang
          end
          nil
        end
      end
    end
  end
end