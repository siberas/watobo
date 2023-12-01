module Watobo
  module Headless
    class Spider
      class TriggerCollection < Collection

        def initialize(driver)
          url = URI.parse driver.current_url

          puts "### TRIGGER COLECTION ###"
          puts url
          # all = driver.find_elements(:xpath, './/*')
          all = driver.find_elements(:tag_name, 'button')
          all.concat driver.find_elements(css: '[type="button"]')
          all_attributes = {}
          all.each do |e|
            attrs =  driver.execute_script("var items = {}; for (index = 0; index < arguments[0].attributes.length; ++index) { items[arguments[0].attributes[index].name] = arguments[0].attributes[index].value }; return items;", e );
            all_attributes[e] = attrs
          end

          all_attributes.each do |e, attrs|
            tag_name = e.tag_name

            self << Trigger.new(url, tag_name, html, val)

            attrs.each do |k, val|
              # get element with 'on'-handlers, e.g. onclick, onmouseover, onerror

              if k =~ /^on/
                html = e.attribute('outerHTML')
                # puts "#{url.path}: #{tag_name} : #{k} = #{val}"
                self << Trigger.new(url, tag_name, html, val)
              end
            end
          end

        end
      end
    end
  end
end