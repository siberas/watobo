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

        def runLogin(chat_list, prefs = {}, &block)
          @@login_mutex.synchronize do
            begin
              @@login_in_progress = true
              login_prefs = Hash.new
              login_prefs.update prefs
              dummy = {:ignore_logout => true, :update_sids => true, :update_session => true, :update_contentlength => true}
              login_prefs.update dummy
              puts "! Start Login ..." #if $DEBUG
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

          if request.method =~ /(post|put)/i
            request.fix_content_length
          else
            request.removeHeader('Content-Length')
          end


          #
          # Engress Handler
          h = Watobo::EgressHandlers.create cprefs[:egress_handler]
          h.execute request unless h.nil?

          #
          # Send request over the wire
          sender = Watobo::Net::Http::Sender.new request, cprefs
          request, response = sender.exec

          # TODO: Update-Sid, Check-Logout
          @sid_cache.update_sids(request.site, response.headers) if cprefs[:update_sids] == true

          [request, response]
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