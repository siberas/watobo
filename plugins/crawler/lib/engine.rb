# @private 
module Watobo #:nodoc: all
  module Crawler

    class Agent < Mechanize

      def initialize(opts)
        super()


        self.verify_mode = OpenSSL::SSL::VERIFY_NONE
        self.ignore_bad_chunking = true
        self.keep_alive = false

        self.user_agent = opts[:user_agent] if opts.has_key?(:user_agent)

        if opts.has_key? :username and opts.has_key? :password
          unless opts[:username].empty? and opts[:password].empty?

            user = opts[:username]
            pw = opts[:password]
            uri = opts[:auth_uri]
            # puts "Got Credentials for #{uri}: #{user} / #{pw}"
            self.add_auth(uri, user, pw)
            # TODO: remove this workaround for a Mechanize Bug (#243)
            p = self.get uri
          end
        end

        if (opts.has_key? :proxy_host) && (opts.has_key? :proxy_port)
          self.set_proxy(opts[:proxy_host], opts[:proxy_port])
        end

        if opts.has_key? :pre_connect_hook
          self.pre_connect_hooks << opts[:pre_connect_hook] if opts[:pre_connect_hook].respond_to? :call
        end

        unless opts[:cookie_jar].nil?
          clean_jar = Mechanize::CookieJar.new
          opts[:cookie_jar].each { |cookie|
            clean_jar.add! cookie
          }
          self.cookie_jar = clean_jar
        end

      end

    end

    class Engine
      include Watobo::Plugin::Crawler::Constants

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listeners[event] ||= []
        @event_dispatcher_listeners[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          # puts "NOTIFY: #{self}(:#{event}) [#{@event_dispatcher_listeners[event].length}]" if $DEBUG
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def settings
        @opts
      end


      def get_page(url, opts = {})
        ro = {}.update @opts
        ro.update opts
        agent = Crawler::Agent.new(ro)
        page = nil
        page = agent.get url
        return agent, page
      end

      def initialize(opts = {})
        @event_dispatcher_listeners = Hash.new
        @status_lock = Mutex.new

        @opts = {
            :submit_forms => true,
            :max_depth => 5,
            :max_repeat => 20,
            :max_threads => 4,
            :user_agent => "watobo-crawler",
            :proxy_host => '127.0.0.1',
            :proxy_port => Watobo::Conf::Interceptor.port,
            :delay => 0,
            :head_request_pattern => '(pdf|swf|doc|flv|jpg|png|gif)',
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
            :cookie_jar => nil
        }

        @opts.update opts
        @opts[:head_request_pattern] = '' if @opts[:head_request_pattern].nil?

        @stats = {
            :total_requests => 0
        }

        @link_keys = Hash.new
        @link_counts = Hash.new

        @form_keys = Hash.new
        @form_counts = Hash.new

      end

      def pause
        false
      end

      def cancel
        puts "[CRAWLER] - CANCEL!!"
        #@status_lock.synchronize do
        #  @engine_status = CRAWL_NONE
        #end
        Watobo::Crawler::Status.engine = CRAWL_NONE
        @grabber_threads.each do |gt|
          puts "Killing Thread #{gt}"
          gt.kill
        end
        @grabber_threads.each { |t| t.join }

        @link_queue.clear
        @page_queue.clear
        @grabber_threads.clear
        @link_keys.clear
        @link_counts.clear

        @form_keys.clear
        @form_counts.clear

        #notify( :update_status, current_status )
        puts "CANCELED - CANCELED"
        # exit
      end

      def run(url, opts = {})
        #engine_status = CRAWL_RUNNING
        Watobo::Crawler::Status.reset
        Watobo::Crawler::Status.engine = CRAWL_RUNNING

        @opts.update opts
        @opts[:head_request_pattern] = '' if @opts[:head_request_pattern].nil?

        puts "crawler settings:"
        puts @opts.to_json


        @link_queue = Queue.new
        @page_queue = Queue.new

        @link_keys = Hash.new
        @link_counts = Hash.new

        @form_keys = Hash.new
        @form_counts = Hash.new

        @skipped_sites = Hash.new

        @grabber_threads = []
        start_link = URI.parse url
        return false if start_link.host.nil?

        allow_host(start_link)

        @link_queue.enq LinkBag.new(start_link, 0)


        notify(:log, "Crawling #{url} started ...")

        @opts[:max_threads].times do |i|
          g = Grabber.new(@link_queue, @page_queue, @opts)
          @grabber_threads << g.run
        end

        puts "* startet #{@grabber_threads.length} grabbers"

        @t_engine = Thread.new {
          loop do
            pagebag = @page_queue.deq

            process_links(pagebag)

            process_forms(pagebag)
            #@stats[:total_requests] += 1 unless pagebag.nil?
            Watobo::Crawler::Status.inc_requests() unless pagebag.nil?
            Watobo::Crawler::Status.page_size = @page_queue.size
            Watobo::Crawler::Status.link_size = @link_queue.size

            puts "Links/Pages: #{@link_queue.size}/#{@page_queue.size}"
            #notify( :update_status, current_status )
            # if @link_queue.empty? and @page_queue.empty?
            if @page_queue.empty?
              # if page_queue is empty wait for all grabber threads finishing the link_queue
              until @link_queue.num_waiting == @grabber_threads.length
                Thread.pass
              end
              # when the link_queue is finished check the page_queue. Crawling is finished if page_queue is empty too.
              if @page_queue.empty?
                @grabber_threads.each { |t| t.kill }
                puts "Finished Crawling"
                #@status_lock.synchronize{ @engine_status = CRAWL_NONE }
                Watobo::Crawler::Status.engine = CRAWL_NONE

                notify(:log, "Crawling finished")
                #notify( :update_status, current_status )
                break

              end
            end

          end
        }
      end

      private

      def current_status
        {
            :engine_status => @engine_status,
            :link_size => @link_queue.size,
            :page_size => @page_queue.size
        }.update @stats

      end


      def allow_host(uri)
        if uri.is_a? URI
          site = uri.site.to_s
          # puts "Valid Site: #{site}"
          ah = allowed_hosts
          ah << site
        end
      end

      def process_forms(pagebag)
        return false unless pagebag.respond_to? :page
        page = pagebag.page
        return false unless page.respond_to? :forms
        page.forms.each do |f|

          action = page.uri.merge f.action unless f.action =~ /^http/
          f.action = action.to_s

          if send_form? f
            # puts "SUBMIT FORM: #{f.action}"
            send_form(f, pagebag.depth)
          end
        end
      end

      def process_links(pagebag)
        return false unless pagebag.respond_to? :page
        page = pagebag.page
        return false unless page.respond_to? :links

        page.links.each do |l|
          begin
            link = l
            next if l.href.nil?

            link = page.uri.merge l.uri unless l.href =~ /^http/
            #  puts "FOLLOW LINK #{link} ?"
            if follow_link? link
              # puts ">> OK"
              submit_link(link, pagebag.depth)
            else
              # puts ">> NO"
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

      end


      def submit_link(link, depth)
        # @link_keys[link_key(link)] = link

        clk = link_key(link, :clear_values => true)
        @link_counts[clk] ||= 0
        @link_counts[clk] += 1
        lk = link_key(link)
        return false if @link_keys.has_key? lk
        @link_keys[lk] = nil
        if @link_counts[clk] < @opts[:max_repeat]
          @link_queue.enq LinkBag.new(link, depth)
        else
          puts "! MAX REPEAT !\nSkipped link #{link}" if $DEBUG
        end
      end

      def form_key(form, opts = {})
        o = {:clear_values => false}
        o.update opts

        fp = "#{form.action}"
        fp << form.method
        if form.request_data =~ /=/
          data = form.request_data.split("&").sort.join("&")
          if o[:clear_values]
            fp << data.gsub(/=[^&]*/, '=')
          else
            fp << data
          end
        end
        fkey = Digest::MD5.hexdigest fp
        fkey
      end

      def send_form(form, depth)
        return false if @engine_status == CRAWL_NONE
        cfk = form_key(form, :clear_values => true)
        @form_counts[cfk] ||= 0
        @form_counts[cfk] += 1

        # @form_keys[form_key(form)] = form
        fk = form_key(form)
        return false if @form_keys.has_key? fk
        @form_keys[fk] = nil
        begin
          if @form_counts[cfk] < @opts[:max_repeat]
            if form.buttons.length > 0
              p = form.click_button
            else
              p = form.submit()
            end
            puts p.class
            @page_queue.enq PageBag.new(p, depth + 1)
          else
            puts "! MAX REPEAT !\nSkipped Form #{form.action}"
          end
        rescue => bang
          puts bang
          puts bang.backtrace
        end
      end

      def send_form?(form)
        # puts "SEND FORM?"
        return false unless engine_running?
        return false unless @opts[:submit_forms] == true
        # puts "> submit_forms"
        return false unless allowed? form.action
        #puts "> allowed"
        return false unless fields_allowed? form
        #puts "> fields allowed"
        return false if form_sent? form
        # puts "> form not sent"
        return true
      end

      def follow_link?(link)
        return false unless allowed? link
        return false if link_is_followed? link
        return true
      end

      def host_allowed?(uri)
        #puts "ALLOWED HOSTS =>"
        #puts allowed_hosts
        #puts "---"
        # puts "Host Allowed?"
        ah = allowed_hosts
        # puts ah.class
        #puts ah
        return false if ah.empty?
        ahc = ah.select { |h| uri.site =~ /^#{h}$/ }.length
        if ahc > 0
          # puts "> Host IS allowed!"
          return true
        end
        # puts "> Host is NOT allowed!"
        return false
      end

      def url_allowed?(uri)
        # puts "* excluded_urls"
        # puts exluded_urls
        return false if excluded_urls.select { |url| uri.path =~ /#{url}/ }.length > 0
        # puts "* allowed_urls"
        # puts allowed_urls
        return true if allowed_urls.empty?
        return true if allowed_urls.select { |url| uri.path =~ /#{url}/ }.length > 0
        # puts "> URL is NOT allowed"
        return false
      end

      def path_allowed?(uri)
        return true if root_path.nil?
        return true if root_path.empty?
        return true if uri.path =~ /^#{root_path}/
        # puts "> PATH is NOT ALLOWED"
        return false
      end

      def cleanup_uri(obj)
        uri = nil
        uri = obj.uri if obj.respond_to? :uri
        uri = URI.parse(obj) if obj.is_a? String
        uri = obj if obj.is_a? URI::HTTP
        uri
      end

      def allowed?(link)
        valid = false
        # need to handle different link objects, Mechanize::Page::Link and URIs
        uri = nil
        uri = link.uri if link.respond_to? :uri
        uri = URI.parse(link) if link.is_a? String
        uri = link if link.is_a? URI::HTTP

        return false if uri.nil?

        host_allowed?(uri) &&
            url_allowed?(uri) &&
            path_allowed?(uri)
      end

      def form_sent?(form)

        @form_keys.has_key? form_key(form)
      end

      def link_key(link, opts = {})
        o = {:clear_values => false}
        o.update opts

        uri = cleanup_uri(link)

        query_sorted = ""
        query_sorted = uri.query.split("&").sort.join("&") unless uri.query.nil?

        key = ""
        key << uri.scheme
        key << uri.site
        key << uri.path
        key << query_sorted
        key.gsub!(/=[^&]*/, '=') if o[:clear_values] == true

        Digest::MD5.hexdigest key
      end

      def engine_running?
        @status_lock.synchronize do
          return false if @engine_status == CRAWL_NONE
          return true
        end
      end

      def link_is_followed?(link)

        return true if @link_keys.has_key? link_key(link)

        false
      end

      def fields_allowed?(form)
        form.fields.each do |f|
          excluded_fields.each do |ef|
            return false if f.name =~ /#{ef}/
          end
        end
        return true
      end

      def method_missing(name, *args, &block)
        #   puts "* instance method missing (#{name})"
        if name =~ /(.*)=$/
          @opts.has_key? $1.to_sym || super
          @opts[$1.to_sym] = args[0]
          return @opts[$1.to_sym]
        else
          k = name.to_sym
          @opts.has_key? k || super
          #   puts "Value Found For #{k.to_yaml}"
          return @opts[k]

        end
      end
    end
  end

end
