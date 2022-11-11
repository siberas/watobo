module Watobo
  module Headless
    class Spider
      class HrefCollection < Collection

        def initialize(driver)
          super()
          hrefs = driver.find_elements(:tag_name, 'a')

          url = driver.current_url

          checked_hrefs = hrefs.map{|h| h.attribute('href') rescue nil  }
          checked_hrefs.compact!
          self.concat checked_hrefs.map { |h| Spider::Href.new(url, h) }

        end
      end
    end
  end
end