module Watobo
  module Headless
    class Spider
      class HrefCollection < Collection

        def initialize(driver)
          super()
          # wait for DOM to have a-tags
          wait = Selenium::WebDriver::Wait.new(timeout: 5)
          wait.until { !driver.find_elements(:tag_name, 'a').empty? }
          sleep 0.3
          atags = driver.find_elements(:tag_name, 'a')

          url = driver.current_url

          # check if elements are still valid, they might be no longer present when DOM has changed
          # during loading phase
          atags = atags.select{|h| h.attribute('href') rescue nil  }

          empty_atags = atags.select{|h| h.attribute('href').strip.empty? }
          non_valid_atags = atags.select{|h| !(URI.parse(h.attribute('href')).host rescue nil) }



          valids = atags.select{|h| h.attribute('href') rescue nil  }
          valids.compact!

          clicks = empty_atags + non_valid_atags

          puts "Found #clicks: #{clicks.size}"

          self.concat valids.map { |h| Spider::Href.new(url, h) }
          self.concat clicks.map { |h| Spider::Click.new(url, h) }

        end
      end
    end
  end
end