require 'watobo/core/subscriber'

module Watobo
  module Net
    module Http
      class Session
        include Watobo::Constants
        include Watobo::Subscriber

        attr :settings, :sid_cache, :ott_cache
        attr_accessor :timeout

        @@login_mutex = Mutex.new
        @@login_cv = ConditionVariable.new

        DEFAULT_PREFS = {
          logout_signatures: [],
          logout_content_types: Hash.new,
          update_valid_sids: false,
          update_sids: false,
          update_otts: false,
          update_session: true,
          update_contentlength: true,
          custom_error_patterns: [],
          login_chats: [],
          www_auth: Hash.new,
          client_certificate: {},
          proxy: nil,
          follow_redirects: false,
          egress_handler: nil,
          timeout: 60

        }

        def initialize(session = nil, prefs = {})
          @ott_cache = nil # Watobo::OTTCache.acquire(request)
          @sid_cache = Watobo::SIDCache.acquire(session)

          @settings = {}
          DEFAULT_PREFS.keys.each do |pk|
            @settings[pk] = prefs.has_key?(pk) ? prefs[pk] : DEFAULT_PREFS[pk]
          end

          @timeout = @settings[:timeout]

          # update_instance_vars(@settings)
          define_getters(@settings)

          puts JSON.pretty_generate @settings if $DEBUG

        end

        def on_header(&block)
          @on_header_cb = block
        end

        def do_header(header)
          @on_header_cb.call(header) if @on_header_cb
        end

        def runLogin(chat_list, prefs = {}, &block)
          @@login_mutex.synchronize do
            begin
              @@login_in_progress = true
              login_prefs = Hash.new
              login_prefs.update prefs
              dummy = { :ignore_logout => true, :update_sids => true, :update_session => true, :update_contentlength => true }
              login_prefs.update dummy
              puts "! Start Login ..." # if $DEBUG
              unless chat_list.empty?
                #  puts login_prefs.to_yaml
                chat_list.each do |chat|
                  puts chat.request.url
                  puts "! LoginRequest: #{chat.id}" if $DEBUG
                  test_req = chat.copyRequest
                  request, response = doRequest(test_req, login_prefs)
                  yield [request, response] if block_given?
                end
              else
                puts "! no login script configured !"
              end
            rescue => bang
              puts "!ERROR in runLogin"
              puts bang.backtrace if $DEBUG
              binding.pry
            ensure
              @@login_in_progress = false
              @@login_cv.signal

            end
          end
        end

        def doRequest(orig, prefs = {})
          request = orig.copy

          cprefs = @settings ? @settings.clone : {}
          # overwrite :timeout with controllable value
          cprefs[:timeout] = timeout
          # get client certificate from ClientCertStore
          cprefs[:client_certificate] = Watobo::ClientCertStore.get request.site
          cprefs.update prefs

          if $VERBOSE
            puts JSON.pretty_generate(cprefs)
          end

          # update session from sid_cache
          @sid_cache.update_request(request) if cprefs[:update_session] == true

          # multipart requests also require a content-length header
          if request.method =~ /(post|put)/i #&& request.content_type !~ /multipart/i
            request.fix_content_length
          else
            request.removeHeader('Content-Length')
          end

          update_tokens(request)

          #
          # Engress Handler
          h = Watobo::EgressHandlers.create cprefs[:egress_handler]

          #puts request.to_s.inspect
          h.execute request unless h.nil?

          #
          # Send request over the wire
          sender = Watobo::Net::Http::Sender.new cprefs
          request, response = sender.exec request

          # puts "!!!!!!!!!!!!!!!!! GOT ANSWER !!!!!!!!!!!!!"
          # TODO: Update-Sid, Check-Logout
          if request && response
            @sid_cache.update_sids(request.site, response.headers) if cprefs[:update_sids] == true
          end

          [request, response]
        end

        def update_tokens(request)

          unless Watobo::OTTCache.requests(request).empty? or @settings[:update_otts] == false
            Watobo::OTTCache.requests(request).each do |req|

              # binding.pry
              copy = Watobo::Request.new YAML.load(YAML.dump(req))

              # updateCSRFToken(csrf_cache, copy)
              ott_cache.update_request(copy)

              socket, ott_request, ott_response = sendHTTPRequest(copy, opts)
              next if socket.nil?
              #  puts "= Response Headers:"
              #  puts csrf_response
              #  puts "==="
              # update_sids(csrf_request.host, csrf_response.headers)
              @sid_cache.update_sids(csrf_request.site, csrf_response.headers) if @settings[:update_sids] == true
              next if socket.nil?
              #  p "*"
              #    csrf_response = readHTTPHeader(socket)
              # binding.pry
              # unless opts.has_key?(:skip_body) and opts[:skip_body] == true
              readHTTPBody(socket, ott_response, ott_request, opts)
              # end

              # response = Response.new(csrf_response)

              next unless ott_response.has_body?

              ott_response.unchunk!
              ott_response.unzip!

              @sid_cache.update_sids(ott_request.site, [ott_response.body]) if @settings[:update_sids] == true

              # updateCSRFCache(csrf_cache, csrf_request, [csrf_response.body]) if csrf_response.content_type =~ /text\//
              ott_cache.update_tokens([ott_response.body]) if ott_response.content_type =~ /text\//

              # socket.close
              closeSocket(socket)
            end
            # p @session[:csrf_requests].length
            # updateCSRFToken(csrf_cache, request)
            ott_cache.update_request(request)
          end

        end

        def loggedOut?(response)
          begin
            return false if @logout_signatures.empty?
            response.each do |line|
              @logout_signatures.each do |p|
                #     puts "!!!*LOGOUT*!!!" if line =~ /#{p}/
                return true if line =~ /#{p}/
              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return false
        end

        alias :logged_out? :loggedOut?

        private

        def update_instance_vars(settings)
          settings.each do |var, val|
            self.instance_variable_set("@#{var.to_s}", val) if DEFAULT_PREFS.keys.include?(var)
          end
        end

        def define_getters(settings)
          settings.each_key do |name|
            # skip timeout because it's a special variable
            next if name.to_s.downcase == 'timeout'

            define_singleton_method(name) do
              return nil unless instance_variable_defined?("@settings")
              settings = instance_variable_get("@settings")
              return nil if settings.nil?
              settings[name]
            end
          end
        end
      end
    end
  end
end