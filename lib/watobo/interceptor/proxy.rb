# @private
module Watobo #:nodoc: all
  module Interceptor
    #
    class Proxy

      include Watobo::Constants

      attr :port

      attr_accessor :proxy_mode

      # attr_accessor :contentLength
      #attr_accessor :contentTypes
      attr_accessor :target
      #attr :www_auth
      attr_accessor :client_certificates

      def self.transparent?
        return true if (Watobo::Conf::Interceptor.proxy_mode & Watobo::Interceptor::MODE_TRANSPARENT) > 0
        return false
      end

      def egress_handler?
        if @target.respond_to? :egress_handler?
          return @target.egress_handler?
        end
        false
      end

      def egress_handler
        if @target.respond_to? :egress_handler
          handler = @target.egress_handler
          return handler
        end
        nil
      end


      def watobo_srv_get(file)
        srv_file = file.empty? ? File.join(@srv_path, 'index.html') : File.join(@srv_path, file)
        if File.exist? srv_file
          ct = case srv_file
               when /\.ico/
                 "image/vnd.microsoft.icon"
               when /\.htm/
                 'text/html; charset=iso-8859-1'
               else
                 'text/plain'
               end
          headers = ["HTTP/1.0 200 OK", "Server: Watobo-Interceptor", "Connection: close", "Content-Type: #{ct}"]
          content = File.open(srv_file, "rb").read
          content.gsub!('WATOBO_VERSION', Watobo::VERSION)
          content.gsub!('WATOBO_HOME', Watobo.working_directory)
          headers << "Content-Length: #{content.length}"
          r = headers.join("\r\n")
          r << "\r\n\r\n"
          r << content
          return r
        end

        headers = ["HTTP/1.0 404 Not Found", "Server: Watobo-Interceptor", "Connection: close", "Content-Type: text/plain; charset=iso-8859-1"]
        content = "The requested file (#{file}) does not exist in the interceptor web folder."
        headers << "Content-Length: #{content.length}"
        r = headers.join("\r\n")
        r << "\r\n\r\n"
        r << content
        return r

      end

      def cert_response
        crt_file = File.join(Watobo.working_directory, "CA", "cacert.pem")
        headers = ["HTTP/1.0 200 OK", "Server: Watobo-Interceptor", "Connection: close", "Content-Type: application/x-pem-file"]
        content = File.read(crt_file)
        headers << "Content-Length: #{content.length}"
        r = headers.join("\r\n")
        r << "\r\n\r\n"
        r << content
      end

      def server
        @bind_addr
      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def getResponseFilter()
        YAML.load(YAML.dump(@response_filter_settings))
      end

      def getRequestFilter()
        YAML.load(YAML.dump(@request_filter_settings))
      end

      def setResponseFilter(new_settings)
        @response_filter_settings.update new_settings unless new_settings.nil?
      end

      def setRequestFilter(new_settings)
        @request_filter_settings.update new_settings unless new_settings.nil?
        # puts @request_filter_settings.to_yaml
      end

      def clear_request_carvers
        @request_carvers.clear unless @request_carvers.nil?

      end

      def clear_response_carvers
        @response_carvers.clear unless @response_carvers.nil?
      end

      def addPreview(response)
        preview_id = Digest::MD5.hexdigest(response.join)
        @preview[preview_id] = response
        return preview_id
      end

      def stop()
        begin
          puts "[#{self.class}] stop"
          if @t_server.respond_to? :status
            Thread.kill @t_server
            @intercept_srv.close
          end
        rescue IOError => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      #
      # R U N
      #

      def self.start(settings = {})
        proxy = Proxy.new(settings)
        proxy.start
        proxy
      end

      def start()
        @wait_queue = Queue.new

        if transparent?
          Watobo::Interceptor::Transparent.start
        end

        begin
          @intercept_srv = TCPServer.new(@bind_addr, @port)
          @intercept_srv.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)

        rescue => bang
          puts "\n!!!Could not start InterceptProxy"
          puts bang
          return nil
        end
        puts "\n* Intercepor started on #{@bind_addr}:#{@port}"
        session_list = []
        puts "!!! TRANSPARENT MODE ENABLED !!!" if transparent?

        @t_server = Thread.new(@intercept_srv) { |server|

          while (new_session = server.accept)
            #  new_session.sync = true
            new_sender = Watobo::SessionV1.new(@target)

            Thread.new(new_sender, new_session) { |sender, session|
              #puts "* got new request from client"
              c_sock = Watobo::HTTPSocket::ClientSocket.connect(session)

              #puts "ClientSocket: #{c_sock}"
              Thread.exit if c_sock.nil?
              Thread.exit unless c_sock.respond_to? :close

              #
              # loop for reusing client connections

              max_loop = 0
              loop do
                flags = []
                begin

                  request = c_sock.request
                  Thread.exit if request.nil?

                  if request.nil? or request.empty? then
                    print "c/"
                    c_sock.close
                    Thread.exit
                  end

                  url = (request.url.to_s.length > 71) ? request.url.to_s.slice(0, 71) + " ..." : request.url.to_s
                  puts "\n[I] #{url}"

                rescue => bang
                  puts "!!! Error reading client request "
                  puts bang
                  if $DEBUG
                    puts bang.backtrace
                    puts request
                    binding.pry

                  end
                  c_sock.close
                  Thread.exit
                end

                #if request.host =~ /safebrowsing.*google\.com/
                #  c_sock.close
                #  Thread.exit
                #end

                # check if preview is requested
                if request.host == 'watobo.localhost' or request.first =~ /WATOBOPreview/ then
                  if request.first =~ /WATOBOPreview=([0-9a-zA-Z]*)/ then
                    hashid = $1
                    response = @preview[hashid]

                    if response then
                      c_sock.write response.join
                      c_sock.close
                    end
                  end
                  #next
                  Thread.exit
                end

                # check for watobo info page
                if request.host =~ /^watobo$/
                  if request.path =~ /watobo\.pem/
                    response = cert_response
                  else
                    response = watobo_srv_get(request.path)
                  end

                  c_sock.write response
                  c_sock.close
                  Thread.exit
                end

                request_intercepted = false
                # no preview, check if interception request is turned on
                if Watobo::Interceptor.rewrite_requests? then
                  Interceptor::RequestCarver.shape(request, flags)
                  # puts "FLAGS >>"
                  # puts flags
                end

                if @target and Watobo::Interceptor.intercept_requests? then
                  if matchRequestFilter(request)
                    @awaiting_requests += 1
                    request_intercepted = true

                    if @target.respond_to? :addRequest
                      Watobo.print_debug "send request to target"
                      @target.addRequest(request, Thread.current)
                      Thread.stop
                    else
                      p "! no target for editing request"
                    end
                    @awaiting_requests -= 1
                  end
                end

                prefs = {
                    :update_sids => true,
                    :update_session => false,
                    :update_contentlength => true,
                    :www_auth => @www_auth
                }


                if egress_handler?
                  prefs[:egress_handler] = egress_handler
                end

                begin
                  puts "+ [PROXY] sending request: \n#{request}\n\n#{prefs.to_json}" if $DEBUG

                  s_sock, req, resp = sender.sendHTTPRequest(request, prefs)

                  # :client_certificates => @client_certificates
                  #)
                  if s_sock.nil? then
                    puts "s_sock is nil! bye, bye, ..."
                    puts request if $DEBUG
                    c_sock.write resp.join unless resp.nil?
                    c_sock.close
                    Thread.exit
                  end

                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                  c_sock.close
                  Thread.exit
                end


                # check if response should be passed through
                #Thread.current.exit if isPassThrough?(req, resp, s_sock, c_sock)
                if isPassThrough?(req, resp, s_sock, c_sock)
                  puts "[Interceptor] PassThrough >> #{req.url}"
                  Watobo::HTTPSocket.close s_sock
                  c_sock.close
                  Thread.exit
                end

                begin
                  missing_credentials = false
                  rs = resp.status
                  auth_type = AUTH_TYPE_NONE
                  if rs =~ /^(401|407)/ then

                    missing_credentials = true

                    resp.each do |rl|
                      if rl =~ /^(Proxy|WWW)-Authenticate: Basic/i
                        auth_type = AUTH_TYPE_BASIC
                        break
                      elsif rl =~ /^(Proxy|WWW)-Authenticate: NTLM/i
                        auth_type = AUTH_TYPE_NTLM
                        break
                      end
                    end
                    # when auth type not basic assume it's ntlm -> ntlm credentials must be set in watobo
                    unless auth_type == AUTH_TYPE_NONE
                      if auth_type == AUTH_TYPE_NTLM
                        if rs =~ /^401/ then
                          resp.push "WATOBO: Server requires (NTLM) authorization, please set WWW_Auth Credentials!"
                          resp.shift
                          resp.unshift "HTTP/1.1 200 OK\r\n"
                        else
                          resp.push "WATOBO: Proxy requires (NTLM) authorization, please set Proxy Credentials!"
                          resp.shift
                          resp.unshift "HTTP/1.1 200 OK\r\n"
                        end
                      end
                    end
                  end

                  # don't try to read body if request method is HEAD
                  unless auth_type == AUTH_TYPE_UNKNOWN or req.method =~ /^head/i
                    sender.readHTTPBody(s_sock, resp, req, :update_sids => true)
                    Watobo::HTTPSocket.close s_sock
                  end

                rescue => bang
                  puts "!!! could not send request !!!"
                  puts bang
                  puts bang.backtrace if $DEBUG
                  #  puts "* Error sending request"
                end

                begin
                  # Watobo::Response.create resp
                  #resp = Watobo::Response.new resp
                  # puts "* unchunk response ..."
                  resp.unchunk!
                  # puts "* unzip response ..."
                  resp.unzip!

                  if Watobo::Interceptor.rewrite_responses? then
                    Interceptor::ResponseCarver.shape(resp, flags)
                  end

                  if @target and Watobo::Interceptor.intercept_responses? then
                    if matchResponseFilter(resp)
                      #  if resp.content_type =~ /text/ or resp.content_type =~ /application\/javascript/ then
                      if @target.respond_to? :modifyResponse
                        @target.modifyResponse(resp, Thread.current)
                        Thread.stop
                      else
                        p "! no target for editing response"
                      end
                    end
                  end

                  # puts ">> SEND TO CLIENT"
                  # puts ">>C<< - Close: #{request.connection_close?}"
                  # request.headers("Connection"){ |h| puts h }

                  if missing_credentials
                    resp.set_header("Connection", "close")
                  elsif request.connection_close? or resp.content_length < 0 or max_loop > 4
                    # resp.set_header("Proxy-Connection","close")
                    resp.set_header("Connection", "close")
                  else
                    resp.set_header("Connection", "keep-alive")
                    resp.set_header("Keep-Alive", "max=4, timeout=120")
                  end

                  resp_data = resp.join
                  c_sock.write resp_data

                  chat = Chat.new(request.copy, resp.copy, :source => CHAT_SOURCE_INTERCEPT)

                  # we have to add chat to the global Chats before we send it to the passive scanner,
                  # because the chat.id is set during add
                  Watobo::Chats.add chat
                  Watobo::PassiveScanner.add(chat)



                rescue Errno::ECONNRESET
                  print "x"
                  #  puts "!!! ERROR (Reset): reading body"
                  #  puts "* last data seen on socket: #{buf}"
                  #return
                  c_sock.close
                  Thread.exit
                rescue Errno::ECONNABORTED
                  print "x"
                  #return
                  c_sock.close
                  Thread.exit
                rescue => bang
                  puts "!!! Error (???) in Client Communication:"
                  puts bang
                  puts bang.class
                  puts bang.backtrace #if $DEBUG
                  #return
                  c_sock.close
                  Thread.exit
                end


                # TODO: place check into ClientSocket, because headers must be checked and changed too
                # e.g. if c_sock.open?
                if missing_credentials or request.connection_close? or resp.content_length < 0 or max_loop > 4
                  c_sock.close
                  Thread.exit
                end

                max_loop += 1

              end
            }

          end
        }
      end

      def refresh_www_auth
        @www_auth = Watobo::Conf::Scanner.www_auth
      end

      def initialize(settings = nil)
        @event_dispatcher_listeners = Hash.new
        @pass_through_hosts = ['safebrowsing.*google(api)?.com$',
                               'download.cdn.mozilla.net',
                               'services.mozilla.com$',
                               'tracking-protection.cdn.mozilla.net$',
                               'classify-client.services.*mozilla.com$'
        ]

        begin

          puts
          puts "=== Initialize Interceptor/Proxy ==="

          #Watobo::Interceptor.proxy_mode = INTERCEPT_NONE

          init_instance_vars

          @srv_path = File.join(File.dirname(__FILE__), 'html')

          @awaiting_requests = 0
          @awaiting_responses = 0

          @request_filter_settings = {
              :site_in_scope => false,
              :method_filter => '(get|post|put)',
              :negate_method_filter => false,
              :negate_url_filter => false,
              :url_filter => '',
              :file_type_filter => '(jpg|gif|png|jpeg|bmp)',
              :negate_file_type_filter => true,

              :parms_filter => '',
              :negate_parms_filter => false
              #:regex_location => 0, # TODO: HEADER_LOCATION, BODY_LOCATION, ALL

          }

          @response_filter_settings = {
              :content_type_filter => '(text|script)',
              :negate_content_type_filter => false,
              :response_code_filter => '2\d{2}',
              :negate_response_code_filter => false,
              :request_intercepted => false,
              :content_printable => true,
              :enable_printable_check => false
          }

          @preview = Hash.new
          @preview['ProxyTest'] = ["HTTP/1.0 200 OK\r\nServer: Watobo-Interceptor\r\nConnection: close\r\nContent-Type: text/html; charset=iso-8859-1\r\n\r\n<html><body>PROXY_OK</body></html>"]

          @dh_key = Watobo::CA.dh_key

        rescue => bang
          puts "!!!could not read certificate files:"
          puts bang
          puts bang.backtrace if $DEBUG
        end

      end

      private

      def init_instance_vars
        @www_auth = Watobo::Conf::Scanner.www_auth
        @fake_certs = {}
        @client_certificates = {}
        @target = nil
        #  @sender = Watobo::Session.new(@target)


        unless ENV['WATOBO_BINDING']
          @bind_addr = Watobo::Conf::Interceptor.bind_addr
          # puts "> Server: #{@bind_addr}"
          @port = Watobo::Conf::Interceptor.port
          # puts "> Port: #{@port}"
          @proxy_mode = Watobo::Conf::Interceptor.proxy_mode
        else
          bip, bport = ENV['WATOBO_BINDING'].split(':')
          @bind_addr = bip
          # puts "> Server: #{@bind_addr}"
          @port = bport
          # puts "> Port: #{@port}"
          @proxy_mode = Watobo::Interceptor::MODE_REGULAR
        end

        pt = Watobo::Conf::Interceptor.pass_through
        @contentLength = pt[:content_length]
        # puts "> PT-ContentLength: #{@contentLength}"
        @contentTypes = pt[:content_types]
        # puts "> PT-ContentTypes: #{@contentTypes}"
      end

      #
      #
      # matchContentType(content_type)
      #
      #
      def matchContentType?(content_type)
        @contentTypes.each do |p|
          return true if content_type =~ /#{p}/
        end
        return false
      end

      #
      #
      # matchRequestFilter(request)
      #
      #
      def matchRequestFilter(request)
        match_url = true
        # puts @request_filter_settings.to_yaml
        url_filter = @request_filter_settings[:url_filter]
        if url_filter != ''
          match_url = false
          if request.url.to_s =~ /#{url_filter}/i
            match_url = true
          end
          if @request_filter_settings[:negate_url_filter] == true
            match_url = (match_url == true) ? false : true
          end
        end

        return false if match_url == false

        match_method = true
        method_filter = @request_filter_settings[:method_filter]
        if method_filter != ''
          match_method = false
          if request.method =~ /#{method_filter}/i
            match_method = true
          end

          if @request_filter_settings[:negate_method_filter] == true
            match_method = (match_method == true) ? false : true
          end
        end

        return false if match_method == false

        match_ftype = true
        ftype_filter = @request_filter_settings[:file_type_filter]
        if ftype_filter != ''
          match_ftype = false
          if request.doctype != '' and request.doctype =~ /#{ftype_filter}/i
            match_ftype = true
          end
          if @request_filter_settings[:negate_file_type_filter] == true
            match_ftype = (match_ftype == true) ? false : true
          end
        end
        return false if match_ftype == false

        match_parms = true
        parms_filter = @request_filter_settings[:parms_filter]
        if parms_filter != ''
          #  puts "!PARMS FILTER: #{parms_filter}"
          match_parms = false
          puts request.parms
          match_parms = request.parms.find { |x| x =~ /#{parms_filter}/ }
          match_parms = (match_parms.nil?) ? false : true
          if @request_filter_settings[:negate_parms_filter] == true
            match_parms = (match_parms == true) ? false : true
          end
        end
        return false if match_parms == false

        true
      end

      #
      #
      # matchResponseFilter(response)
      #
      #

      def matchResponseFilter(response)
        match_ctype = true
        ct_filter = @response_filter_settings[:content_type_filter]
        unless ct_filter.empty?
          match_ctype = false
          negate = @response_filter_settings[:negate_content_type_filter]
          if response.content_type =~ /#{ct_filter}/
            match_ctype = true

          end
          if negate == true
            match_ctype = (match_ctype == true) ? false : true
          end
        end
        return false if match_ctype == false
        #puts "* pass ctype filter"
        match_rcode = true
        rcode_filter = @response_filter_settings[:response_code_filter]
        negate = @response_filter_settings[:negate_response_code_filter]
        unless rcode_filter.empty?
          match_rcode = false
          puts rcode_filter
          puts response.responseCode
          if response.responseCode =~ /#{rcode_filter}/
            match_rcode = true
          end
          if negate == true
            match_rcode = (match_rcode == true) ? false : true
          end
        end
        return false if match_rcode == false
        #puts "* pass rcode filter"
        true
      end

      #
      #
      # pass_through(server, client, maxbytes)
      #
      #
      def pass_through(server, client, maxbytes = 0)

        bytes_read = 0
        while 1
          begin
            #timeout(2) do
            buf = nil
            buf = server.readpartial(2048)
              #end
          rescue EOFError
            #client.write buf if buf
            #print "~]"
            # msg = "\n[pass_through] EOF - "
            # msg += buf.nil? ? "nil" : buf.size
            #   puts msg
            return if buf.nil?
          rescue Errno::ECONNRESET
            # puts "!!! ERROR (Reset): reading body"
            # puts "* last data seen on socket: #{buf}"
            # msg = "!R - "
            # msg += buf.nil? ? "nil" : buf.size
            # msg << " !\n"
            #   puts msg

            return if buf.nil?
          rescue Timeout::Error
            #puts "!!! ERROR (Timeout): reading body"
            #puts "* last data seen on socket:"
            #client.write buf if buf
            print "T"
            return
          rescue => bang
            puts "!!! could not read body !!!"
            puts bang
            puts bang.class
            puts bang.backtrace if $DEBUG
            # puts "* last data seen on socket:"
            # print "~]"
            #client.write buf if buf
            return
          end

          begin
            return if buf.nil?
            # print "~"
            client.write buf
            bytes_read += buf.length
            # puts "#{server} #{bytes_read} of #{maxbytes}"
            if maxbytes > 0 and bytes_read >= maxbytes
              #print "~]"
              return
            end
          rescue Errno::ECONNRESET
            #print "~x]"
            #  puts "!!! ERROR (Reset): reading body"
            #  puts "* last data seen on socket: #{buf}"
            return
          rescue Errno::ECONNABORTED
            # print "~x]"
            return
          rescue Errno::EPIPE
            # print "~x]"
            return
          rescue => bang
            puts "!!! client communication broken !!!"
            puts bang
            puts bang.class
            puts bang.backtrace if $DEBUG
            return
          end
        end
      end

      def transparent?
        (@proxy_mode & Watobo::Interceptor::MODE_TRANSPARENT) > 0
      end

      def isPassThrough?(request, response, s_sock, c_sock)
        begin
          # return false if true
          reason = nil
          clen = response.content_length

          # TODO: replace with modular pass-through rules
          if request.has_body?
            # puts "PassThrough Check #{request.url}"
            if request.url.to_s =~ /https:..fi.*ebp.*test.*/
              b = request.body.to_s
              # puts b
              if b =~ /cmd_0=dummy/
                c_sock.write response.join
                pass_through(s_sock, c_sock, clen)
                return true
              end
            end
          end


          # no pass-through necessary if request method is HEAD
          return false if request.method =~ /^head/i

          if matchContentType?(response.content_type) then
            # first forward headers
            #c_sock.write response.join
            reason = []
            reason.push "---> WATOBO: PASS_THROUGH <---"
            reason.push "Reason: Content-Type = #{response.content_type}"
          elsif clen > @contentLength
            # puts "PASS-THROUGH: #{response.content_length}"
            #c_sock.write response.join
            reason = []
            reason.push "---> WATOBO: PASS_THROUGH <---"
            reason.push "Reason: Content-Length > #{@contentLength} (#{response.content_length})"
          end

          @pass_through_hosts.each do |p|
            if request.host =~ /#{p}/
              c_sock.write response.join
              pass_through(s_sock, c_sock, clen)
              return true
            end
          end

          return false if reason.nil?

          response.remove_header("Keep-Alive")
          response.set_header("Connection", "close")

          c_sock.write response.join

          reason.push "* DO MANUAL REQUEST TO GET FULL RESPONSE *"
          response.push reason.join("\n")
          chat = Watobo::Chat.new(request, response, :source => CHAT_SOURCE_INTERCEPT)
          #notify(:new_interception, chat)
          Watobo::Chats.add chat
          #Watobo::PassiveScanner.add(chat)

          pass_through(s_sock, c_sock, clen)
          #  puts "* Close Server Socket..."
          #closeSocket(c_sock)
          #  puts "* Close Client Socket..."
          #closeSocket(s_sock)
          #  puts "... done."
          return true
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return false
      end

    end
  end
end
