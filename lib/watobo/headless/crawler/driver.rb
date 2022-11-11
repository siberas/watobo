module Watobo
  module Headless
    class Spider
      class Driver
        attr :driver, :runner

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


            @driver.execute_script( resource.script )

          end

          collection.concat Spider::HrefCollection.new(@driver)

          collection.concat Spider::TriggerCollection.new(@driver)

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
          prefs = {proxy: nil, headless: true}.update opts
          proxy = prefs[:proxy]
          headless = !!prefs[:headless]
          # configure the driver to run in headless mode
          @options = Selenium::WebDriver::Chrome::Options.new

          @options.add_argument('--headless') if headless
          @options.add_argument('--allow-file-access-from-files')

          if proxy
            @options.add_argument('--proxy-server=%s' % proxy)
          end

          # This didn't work
          # @driver = Selenium::WebDriver::Chrome(chrome_options=@options,
          #                          executable_path='/usr/share/chrome-linux/')

          Selenium::WebDriver::Chrome::Service.driver_path = prefs[:driver_path] if prefs[:driver_path]

          @driver = Selenium::WebDriver.for :chrome, options: @options

        end
      end
    end
  end
end