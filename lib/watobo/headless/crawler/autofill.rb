module Watobo
  module Headless
    class Spider
      class Autofill
        attr :driver


        #
        # <input type="button">
        # <input type="checkbox">
        # <input type="color">
        # <input type="date">
        # <input type="datetime-local">
        # <input type="email">
        # <input type="file">
        # <input type="hidden">
        # <input type="image">
        # <input type="month">
        # <input type="number">
        # <input type="password">
        # <input type="radio">
        # <input type="range">
        # <input type="reset">
        # <input type="search">
        # <input type="submit">
        # <input type="tel">
        # <input type="text">
        # <input type="time">
        # <input type="url">
        # <input type="week">
        def fill_input(element)
          type = element.attribute('type')

          placeholder = element.attribute('placeholder')
          current_value = get_value(element)
          puts "Current Placeholder: #{placeholder}"
          puts "Current Value: #{current_value}"

          value = current_value.empty? ? nil : current_value
          if placeholder =~ /^http/
            value = "http://www.google.com/four_four"
          end

          unless value
            value = case type
                    when /checkbox/
                      'checkbox'
                    when /text/
                      "lorem ipsum"
                    when /url/
                      "http://www.google.com/four_four"
                    when /file/
                      tmpfile = '/tmp/xxx'
                      id = element.attribute('id')

                      if id
                      File.open(tmpfile, 'w') { |fh| fh.puts "gaga" }
                      driver.execute_script("const i = document.getElementById('#{id}'); alert(i.outerHTML); const dataTransfer = new DataTransfer(); file = new File(['#{tmpfile}'], 'hello', {type: 'text/plain'}); dataTransfer.items.add(file); i.files = dataTransfer.files");
                      end

                      nil
                    end
          end
          puts "Fill <input type='#{type}'> : #{value}"

          set_value(element, value) if value
        end

        def fill_textarea(element)

        end

        def set_value(element, value)
          driver.execute_script("arguments[0].value='#{value}';", element);
        end

        def get_value(element)
          element.attribute('value')
        end

        def fill!
          inputs = driver.find_elements(:tag_name, 'input')
          inputs.map { |i| fill_input(i) }

          return
          selects = driver.find_elements(:tag_name, 'select')
          files = driver.find_elements(:tag_name, 'file')
          textareas = driver.find_elements(:tag_name, 'textarea')

        end

        def initialize(driver)
          @driver = driver
        end


      end
    end
  end
end