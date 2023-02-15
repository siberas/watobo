module Watobo
  module Headless
    class Spider
      class FormCollection < Collection

        def initialize(driver)
          super()

          forms = driver.find_elements(:tag_name, 'form')
          url = driver.current_url

          # check if elements are still valid, they might be no longer present when DOM has changed
          # during loading phase
          active_forms = forms.select{|e| e.attribute('action') rescue false  }

          active_forms.each do |form|

            attrs = driver.execute_script("var items = {}; for (index = 0; index < arguments[0].attributes.length; ++index) { items[arguments[0].attributes[index].name] = arguments[0].attributes[index].value }; return items;", form);
            puts attrs.to_json
            self.concat active_forms.map { |e| Spider::Form.new(url, attrs) }
          end


        end
      end
    end
  end
end
