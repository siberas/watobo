module Watobo
  module Headless
    class Spider
      class Driver
        attr :driver, :runner

        def process_form(form)
          # only reload if url of script is different to current
          # not sure if it will work nicely but it will be faster
          driver.navigate.to form.src if form.src != driver.current_url
          begin
            filler = Spider::Autofill.new(driver)
            filler.fill!
          rescue => bang
            binding.pry if $DEBUG
          end

          f = driver.find_element(:css, "form[action='#{form.attributes.action}']")
          f.submit



        end

        def collect(resource)
          # print '.' if $VERBOSE
          collection = []
          if resource.is_a? Href
            #return collection unless resource.respond_to?(:href)
            @driver.navigate.to resource.href
          end

          if resource.is_a? Trigger
            # only reload if url of script is different to current
            # not sure if it will work nicely but it will be faster
            @driver.navigate.to resource.src if resource.src != driver.current_url

            # puts "Executing #{resource.script}"
            begin
               filler = Spider::Autofill.new(driver)
               filler.fill!
            rescue => bang
              binding.pry if $DEBUG
             end

            #puts resource.script

            @driver.execute_script( resource.script )

          end

          process_form(resource) if resource.is_a? Form

          collection.concat Spider::HrefCollection.new(@driver)

          collection.concat Spider::TriggerCollection.new(@driver)

          collection.concat Spider::FormCollection.new(@driver)

          collection
        end

        def run!
          @runner = Thread.new(@in_queue, @out_queue) { |inq, outq|
            loop do
              begin
                #link, referer, depth = lq.deq

                outq << nil
                Thread.current[:xxx] = :waiting
                resource = inq.deq
                Thread.current[:xxx] = :working
                t_start = Process.clock_gettime(Process::CLOCK_REALTIME)
                #next if link.depth > @opts[:max_depth]
                results = collect(resource)
                t_end = Process.clock_gettime(Process::CLOCK_REALTIME)
                results.each do |r|
                  outq.enq r
                end
                duration = t_end - t_start
                #puts "Took: #{duration}"
                outq << Stat.new(resource, duration )

              rescue => bang
                puts bang
                puts bang.backtrace #if $DEBUG
              end
            end
          }
          @runner
        end

        def initialize(in_queue, out_queue, opts = {})
          @in_queue = in_queue
          @out_queue = out_queue
          prefs = {
            proxy: nil,
            headless: true,
            chrome_bundle_path: '/usr/share/chrome-driver'
          }.update opts

          proxy = prefs[:proxy]
          headless = !!prefs[:headless]
          # configure the driver to run in headless mode
          @options = Selenium::WebDriver::Chrome::Options.new

          @options.add_argument('--headless') if headless
          @options.add_argument('--allow-file-access-from-files')
          @options.add_argument('--ignore-certificate-errors')

          if proxy
            @options.add_argument('--proxy-server=%s' % proxy)
          end

          # This didn't work
          # @driver = Selenium::WebDriver::Chrome(chrome_options=@options,
          #                          executable_path='/usr/share/chrome-linux/')

          Selenium::WebDriver::Chrome::Service.driver_path = File.join(prefs[:chrome_bundle_path],'chromedriver') #prefs[:driver_path] if prefs[:driver_path]
          #Selenium::WebDriver::Chrome.executable_path = File.join(prefs[:driver_path],'chrome')
          Selenium::WebDriver::Chrome.path = File.join(prefs[:chrome_bundle_path],'chrome')

          @driver = Selenium::WebDriver.for :chrome, options: @options

          at_exit do
            @driver.quit
          end


        end
      end
    end
  end
end