module Watobo
  module Headless
    class Spider

      def print_stats
        @stats.each do |stat|
          out = "{ #{stat.duration.round(2)} } #{stat.resource.to_s}"
          puts out
        end
      end

      def process_href(href)
        return unless valid?(href)

        return if @href_keys[href.fingerprint]

        #puts "process href: #{href.href}"

        @href_keys[href.fingerprint] = true
        @in_queue.enq href

      end

      def process_trigger(trigger)
        @trigger_keys ||= {}
        return unless valid?(trigger)
        tk = trigger.fingerprint
        return if @trigger_keys[tk]

        #puts "* found new trigger: #{trigger.src} >> #{trigger.tag_name} : #{trigger.script}"
        @trigger_keys[tk] = true
        @in_queue.enq trigger
      end

      def valid?(input)
        if input.is_a? Href
          return valid_href?(input)
        elsif input.is_a? Trigger
          return valid_trigger?(input)
        end
        false
      end

      def valid_trigger?(input)
        # TODO: implent some filter capabilities
        return true
      end

      def valid_href?(input)
        @allowed_hosts.each do |ah|
          return true if input.match_host?(ah)
        end
        false
      end


      def process(resource)
        return if resource.nil?
        if resource.is_a? Href
          process_href(resource)
        elsif resource.is_a? Trigger
          process_trigger(resource)
        elsif resource.is_a? Stat
          @stats << resource
        end
      end

      def wait
        while @ctrl_th.alive?
          sleep 1
        end
      end

      def href_count
        s = @stats.map{|s| s.resource.class.to_s.gsub(/.*::/,'').downcase }
        s.count 'href'

      end

      def run(url, prefs = {})
        opts = @opts.update(prefs)
        @in_queue = Queue.new
        @out_queue = Queue.new
        @max_drivers = !!opts[:num_browsers] ? opts[:num_browsers] : 1
        @drivers = []

        uri = URI.parse url
        t_start = Process.clock_gettime(Process::CLOCK_REALTIME)

        @allowed_hosts = [uri.host]
        @max_drivers.times do
          d = Spider::Driver.new(@in_queue, @out_queue, opts)
          @drivers << d.run!
        end

        @in_queue << Href.new(url, url)

        last_stats = ''
        @ctrl_th = Thread.new {
          finished = false
          loop do
            stats = "IN(#{@in_queue.size}) OUT(#{@out_queue.size}) WAITING(#{@in_queue.num_waiting})" if $VERBOSE
            #puts stats if last_stats.empty? or stats != last_stats
            last_stats = stats
            t_now = Process.clock_gettime(Process::CLOCK_REALTIME)
            finished = true if (t_now - t_start) > @opts[:max_duration]

            finished = true if href_count >= @opts[:max_visits]

            if @out_queue.size > 0
              element = @out_queue.deq
              process(element)

            else
              driver_states = @drivers.map { |d| d[:xxx] }
              #puts driver_states
              if driver_states.count(:waiting) == @drivers.length
                if @in_queue.size == 0 and @in_queue.num_waiting == @drivers.length
                  finished = true
                end
              end

              if finished
                puts "Crawler finished :)"

                @drivers.each { |t| t.kill }
                t_end = Process.clock_gettime(Process::CLOCK_REALTIME)

                puts "Num visited pages: #{href_count}"
                puts "Duration: #{ (t_end - t_start).round(2) }"
                break
              end
              sleep 1
            end
          end
        }
      end

      def initialize(opts = {})
        @status_lock = Mutex.new
        @stats = []
        @href_keys = {}

        @opts = {
            :autofill => true,
            :max_depth => 5,
            :max_repeat => 20,
            :max_threads => 4,
            :max_duration => 3600,
            :max_visits => 200,
            :user_agent => "Sp1der",
            :proxy => nil,
            :delay => 0,
            :ignore_file_pattern => '(pdf|swf|doc|flv|jpg|png|gif)',
            :allowed_hosts => [], # regex's
            :allowed_urls => [], # regex's
            :excluded_urls => ["logout"], # regex's
            :excluded_fields => ["userid", "username", "password"], # regex's'
            :excluded_form_names => [], # regex's'
            :root_path => "", # regex
            :username => "",
            :password => "",
            :auth_uri => nil,
            :auth_domain => "", # for ntlm auth
        }

        @opts.update opts
        @opts[:head_request_pattern] = '' if @opts[:head_request_pattern].nil?


      end
    end
  end
end