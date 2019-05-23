# @private 
module Watobo#:nodoc: all

  class Session

    include Watobo::Constants
    include Watobo::Subscriber

    attr :settings

    @@settings = Hash.new
    @@proxy = Hash.new

    @@session_lock = Mutex.new

    @@login_mutex = Mutex.new
    @@login_cv = ConditionVariable.new
    @@login_in_progress = false


    def runLogin(chat_list, prefs={})
      #puts @session.object_id
      @@login_mutex.synchronize do
        begin
          @@login_in_progress = true
          login_prefs = Hash.new
          login_prefs.update prefs
          dummy = {:ignore_logout => true, :update_sids => true, :update_session => true, :update_contentlength => true}
          login_prefs.update dummy
          puts "! Start Login ..." if $DEBUG
          unless chat_list.empty?
            #  puts login_prefs.to_yaml
            chat_list.each do |chat|
              puts "! LoginRequest: #{chat.id}" if $DEBUG
              test_req = chat.copyRequest
              request, response = doRequest(test_req, login_prefs)
            end
          else
            puts "! no login script configured !"
          end
        rescue => bang
          puts "!ERROR in runLogin"
          puts bang.backtrace if $DEBUG
        ensure
          @@login_in_progress = false
          @@login_cv.signal

        end
      end
    end

    def sessionSettings()
      @@settings
    end

    # sendHTTPRequest
    # returns Socket, ResponseHeader
    def sendHTTPRequest(request, prefs={})
      begin
        @lasterror = nil
        response_header = nil

        site = request.site
        #   proxy = getProxy(site)
        proxy = Watobo::ForwardingProxy.get(site)

        unless proxy.nil?
          host = proxy.host
          port = proxy.port
        else
          host = request.host
          port = request.port
        end
        # check if hostname is valid and can be resolved
        hostip = IPSocket.getaddress(host)
        # update current preferences, prefs given here are stronger then global settings!
        current_prefs = Hash.new
        [:update_session, :update_sids, :update_contentlength, :ssl_cipher, :www_auth, :client_certificates, :egress_handler ].each do |k|
          current_prefs[k] = prefs[k].nil? ? @session[k] : prefs[k]
        end

        @sid_cache.update_request(request) if current_prefs[:update_session] == true

        #---------------------------------------
        # request.removeHeader("^Proxy-Connection") #if not use_proxy
        # request.removeHeader("^Connection") #if not use_proxy

        # !!!
        # remove Accept-Encoding header
        # otherwise we won't get the content-length information for pass-through feature
        request.removeHeader("^Accept-Encoding")
        # If-Modified-Since: Tue, 28 Oct 2008 11:06:43 GMT
        # If-None-Match: W/"3975-1225192003000"
        # request.removeHeader("^If-")
        #  puts
        #  request.each do |line|
        #  puts line.unpack("H*")
        #end
        #puts
        if current_prefs[:update_contentlength] == true and request.has_body? then
          #puts request.body.unpack("H*")[0]
          #puts (request.body.unpack("H*")[0].length / 2).to_s

          request.fix_content_length()
          #puts "New: #{request.content_length}"
          #puts request.body.encoding
          #puts "--"
        end

        #
        # Engress Handler
        unless current_prefs[:egress_handler].nil?
          unless current_prefs[:egress_handler].empty?
            h = Watobo::EgressHandlers.create current_prefs[:egress_handler]
            unless h.nil?
              h.execute request
            end
          end
        end


        #request.add_header("Via", "Watobo") if use_proxy
        #puts request
        # puts "=============="
      rescue SocketError
        puts "!!! unknown hostname #{host}"
        puts request.first
        return nil, "WATOBO: Could not resolve hostname #{host}", nil
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end

      begin
        unless proxy.nil?
          # connection requires proxy
          # puts "* use proxy #{proxy.name}"

          # check for regular proxy authentication
          if request.is_ssl?
            socket, response_header = sslProxyConnect(request, proxy, current_prefs)
            return socket, response_header, error_response("Could Not Connect To Proxy: #{proxy.name} (#{proxy.host}:#{proxy.port})\n", "#{response_header}") if socket.nil?

            if current_prefs[:www_auth].has_key?(site)
              case current_prefs[:www_auth][site][:type]
              when AUTH_TYPE_NTLM
                #  puts "* found NTLM credentials for site #{site}"
                socket, response_header = wwwAuthNTLM(socket, request, current_prefs[:www_auth][site])

              else
                puts "* Unknown Authentication Type: #{current_prefs[:www_auth][site][:type]}"
              end
            else

              data = request.join + "\r\n"
              unless socket.nil?
                socket.print data
                response_header = readHTTPHeader(socket, current_prefs)
              end
            end
            return socket, Request.new(request), Response.new(response_header)
          end
          #  puts "* doProxyRequest"
          socket, response_header = doProxyRequest(request, proxy, current_prefs)
          #   puts socket.class
          return socket, response_header, error_response("Could Not Connect To Proxy: #{proxy.name} (#{proxy.host}:#{proxy.port})\n", "#{response_header}") if socket.nil?

          return socket, Request.new(request), Response.new(response_header)
        else
          # direct connection to host
          tcp_socket = nil
          #  timeout(6) do
          #puts "* no proxy - direct connection"
          tcp_socket = TCPSocket.new( host, port )
          #optval = [1, 5000].pack("I_2")
          #tcp_socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
          #tcp_socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval    
          tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)    
          #tcp_socket.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1
          tcp_socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)

          tcp_socket.sync = true

          socket =  tcp_socket
          if request.is_ssl?
            ssl_prefs = {}
            ssl_prefs[:ssl_cipher] = current_prefs[:ssl_cipher] if current_prefs.has_key? :ssl_cipher
            #if current_prefs.has_key? :client_certificates
            #  if current_prefs[:client_certificates].has_key? request.site
            #    puts "* use ssl client certificate for site #{request.site}" if $DEBUG
            #    ssl_prefs[:ssl_client_cert] = current_prefs[:client_certificates][request.site][:ssl_client_cert] 
            #    ssl_prefs[:ssl_client_key] = current_prefs[:client_certificates][request.site][:ssl_client_key]
            #  end              
            #end
            unless Watobo::ClientCertStore.get(site).nil?
              # puts "* using client cert for site #{site}"
              client_cert = Watobo::ClientCertStore.get(site)
              ssl_prefs[:client_certificate] = client_cert
            end
            # need hostname for SNI (Server Name Indication)
            # http://en.wikipedia.org/wiki/Server_Name_Indication
            ssl_prefs[:hostname] = host
            socket = sslConnect(tcp_socket, ssl_prefs)
            # puts "SSLSocket " + (socket.nil? ? "NO" : "OK")
            return nil, request, [] if socket.nil?
          end
          #puts socket.class
          # remove URI before sending request but cache it for restoring request
          uri_cache = nil
          uri_cache = request.removeURI #if proxy.nil?
          # request.addHeader("Proxy-Connection", "Close") unless proxy.nil?
          # request.set_header("Accept-Encoding", "gzip;q=0;identity; q=0.5, *;q=0") #don't want encoding

          # request.set_header("Connection", "close") unless request.has_header?("Upgrade") 

          if current_prefs[:www_auth].has_key?(site)
            case current_prefs[:www_auth][site][:type]
            when AUTH_TYPE_NTLM
              # puts "* found NTLM credentials for site #{site}"
              socket, response_header = wwwAuthNTLM(socket, request, current_prefs[:www_auth][site])
              request.restoreURI(uri_cache)

            else
              puts "* Unknown Authentication Type: #{current_prefs[:www_auth][site][:type]}"
            end
          else
            # puts "========== Add Headers"

            request.set_header("Connection", "close") #if not use_proxy

            data = request.join
            unless request.has_body? 
              data << "\r\n" unless data =~ /\r\n\r\n$/ 
            end

            #  puts "\n*** SENDING ..."
            #  puts data
            #  if request.has_body?
            #    puts request.body.length
            #    bhex = request.body.unpack("H*")[0]
            #    puts bhex
            #    puts bhex.length
            #  end



            #puts "= SESSION ="
            #puts data
            #puts data.unpack("H*")[0]#.gsub(/0d0a/,"0d0a\n")
            # puts "---"
            unless socket.nil?                
              socket.print data
              socket.flush
              response_header = readHTTPHeader(socket, current_prefs)
            end
            # RESTORE URI FOR HISTORY/LOG
            request.restoreURI(uri_cache)

          end
          return socket, Watobo::Request.new(request), Watobo::Response.new(response_header)
        end

      rescue Errno::ECONNREFUSED
        response = error_response "connection refused (#{host}:#{port})"
        puts response
        socket = nil
      rescue Errno::ECONNRESET
        response = error_response "connection reset (#{host}:#{port})"
        socket = nil
      rescue Errno::ECONNABORTED
        response = error_response "connection aborted (#{host}:#{port})"
        socket = nil
      rescue Errno::EHOSTUNREACH
        response = error_response "host unreachable (#{host}:#{port})"
        socket = nil
      rescue Timeout::Error
        #request = "WATOBO: TimeOut (#{host}:#{port})\n"
        response = error_response "TimeOut (#{host}:#{port})"
        socket = nil
      rescue Errno::ETIMEDOUT
        puts "TimeOut (#{host}:#{port})"
        response = error_response "TimeOut (#{host}:#{port})"
        socket = nil
      rescue Errno::ENOTCONN
        puts "!!!ENOTCONN"
      rescue OpenSSL::SSL::SSLError
        response = error_response "SSL-Error", $!.to_s + "<br>" + $!.backtrace.join("<br>")
        socket = nil
      rescue => bang
        response = error_response "ERROR:", "#{bang}\n#{bang.backtrace}"
        socket = nil

        puts bang
        puts bang.backtrace if $DEBUG
      end
      #puts response
      return socket, request, response
    end

    def sidCache()
      #puts @project
      @session[:valid_sids]
    end

    def setSIDCache(new_cache = {} )
      @session[:valid_sids] = new_cache if new_cache.is_a? Hash
    end

    # +++ doRequest(request)  +++
    # + function:
    #
    def doRequest(request, opts={} )
      begin
        ott_cache = Watobo::OTTCache.acquire(request)
        @session.update opts
        #  puts "[doRequest] #{@session.to_yaml}"
        # puts "#[#{self.class}]" + @session[:csrf_requests].first.object_id.to_s
        # unless @session[:csrf_requests].empty? or @session[:csrf_patterns].empty?
        unless Watobo::OTTCache.requests(request).empty? or @session[:update_otts] == false
          Watobo::OTTCache.requests(request).each do |req|

            copy = Watobo::Request.new YAML.load(YAML.dump(req))

            #updateCSRFToken(csrf_cache, copy)
            ott_cache.update_request(copy)
            socket, csrf_request, csrf_response = sendHTTPRequest(copy, opts)
            next if socket.nil?
            #  puts "= Response Headers:"
            #  puts csrf_response
            #  puts "==="
            #update_sids(csrf_request.host, csrf_response.headers)
            @sid_cache.update_sids(csrf_request.site, csrf_response.headers) if @session[:update_sids] == true
            next if socket.nil?
            #  p "*"
            #    csrf_response = readHTTPHeader(socket)
            readHTTPBody(socket, csrf_response, csrf_request, opts)

            # response = Response.new(csrf_response)


            next unless csrf_response.has_body?

            csrf_response.unchunk!
            csrf_response.unzip! 

            @sid_cache.update_sids(csrf_request.site, [csrf_response.body]) if @session[:update_sids] == true

            # updateCSRFCache(csrf_cache, csrf_request, [csrf_response.body]) if csrf_response.content_type =~ /text\//
            ott_cache.update_tokens( [csrf_response.body]) if csrf_response.content_type =~ /text\//

            # socket.close
            closeSocket(socket)
          end
          #p @session[:csrf_requests].length
          #updateCSRFToken(csrf_cache, request)
          ott_cache.update_request(request)
        end

        socket, request, response = sendHTTPRequest(request, opts)

        if socket.nil?
          return request, response
          #return request, nil
        end

        @sid_cache.update_sids(request.site, response.headers) if @session[:update_sids] == true

        if @session[:follow_redirect]
          # puts response.status
          if response.status =~ /^30(1|2|8)/
            #response.extend Watobo::Mixin::Parser::Web10
            #request.extend Watobo::Mixin::Shaper::Web10

            loc_header = response.headers("Location:").first
            new_location = loc_header.gsub(/^[^:]*:/,'').strip
            unless new_location =~ /^http/
              if new_location =~ /^\//
                new_location = request.proto + "://" + request.site  + new_location      
              else
                new_location = request.proto + "://" + request.site + "/" + request.dir + "/" + new_location.sub(/^[\.\/]*/,'')
              end
            end

            notify(:follow_redirect, new_location)
            nr = Watobo::Request.new YAML.load(YAML.dump(request))

            # create GET request for new location
            nr.replaceMethod("GET")
            nr.removeHeader("Content-Length")
            nr.removeBody()
            nr.replaceURL(new_location)


            socket, request, response = sendHTTPRequest(nr, opts)

            if socket.nil?
              #return nil, request
              return request, response
            end
          end
        end

        readHTTPBody(socket, response, request, opts)

        unless response.body.nil?
          @sid_cache.update_sids(request.site, [response.body]) if @session[:update_sids] == true and response.content_type =~ /text\//
        end

        #socket.close
        closeSocket(socket)

      rescue  => bang
        #  puts "! Error in doRequest"
        puts "! Module #{Module.nesting[0].name}"
        puts bang
        puts bang.backtrace if $DEBUG
        @lasterror = bang
        # raise
        # ensure
      end

      #response.extend Watobo::Mixin::Parser::Web10
      # resp = Watobo::Response.new(response)

      response.unchunk!
      response.unzip!

      return Request.new(request), response
    end

    def addProxy(prefs=nil)

      proxy = nil
      unless prefs.nil?
        proxy = Proxy.new(prefs)
        #  proxy.setCredentials(prefs[:credentials]) unless prefs[:credentials].nil?
        unless prefs[:site].nil?
          @@proxy[prefs[:site]] = proxy
          return
        end
      end

      @@proxy[:default] = proxy
    end

    def get_settings
      @@settings
    end

    def getProxy(site=nil)
      unless site.nil?
        return @@proxy[site] unless @@proxy[site].nil?
      end
      return @@proxy[:default]
    end

    #
    # INITIALIZE
    #
    # Possible preferences:
    # :proxy => '127.0.0.1:port'
    # :valid_sids => Hash.new,
    # :sid_patterns => [],
    # :logout_signatures => [],
    # :update_valid_sids => false,
    # :update_sids => false,
    # :update_contentlength => true
    def initialize( session_id=nil, prefs={} )

      @event_dispatcher_listeners = Hash.new
      #     @session = {}

      session = nil

      session = ( session_id.is_a? Integer ) ? session_id : session_id.object_id
      session = Digest::MD5.hexdigest(Time.now.to_f.to_s) if session_id.nil?

      @sid_cache = Watobo::SIDCache.acquire(session)

      unless @@settings.has_key? session
        @@settings[session] = {
          :logout_signatures => [],
          :logout_content_types => Hash.new,
          :update_valid_sids => false,
          :update_sids => false,
          :update_otts => false,           
          :update_session => true,
          :update_contentlength => true,
          :login_chats => [],
          :www_auth => Hash.new,
          :client_certificates => {},
          :proxy_auth => Hash.new
        }
      end
      @session = @@settings[session] # shortcut to settings
      @session.update prefs

      #  @valid_csrf_tokens = Hash.new

      addProxy( prefs[:proxy] ) if prefs.is_a? Hash and prefs[:proxy]

      @socket = nil

      @ctx = OpenSSL::SSL::SSLContext.new()
      @ctx.key = nil
      @ctx.cert = nil

      # TODO: Implement switches for URL-Encoding (http://www.blooberry.com/indexdot/html/topics/urlencoding.htm)
      # TODO: Implement switches for Following Redirects
      # TODO: Implement switches for Logging, Debugging, ...
    end

    def readHTTPBody(socket, response, request, prefs={})
      clen = response.content_length
      data = ""

      begin
        if response.is_chunked?
          Watobo::HTTPSocket.readChunkedBody(socket) { |c|
            data += c
          }
        elsif  clen > 0
          #  puts "* read #{clen} bytes for body"
          Watobo::HTTPSocket.read_body(socket, :max_bytes => clen) { |c|

            data += c
            break if data.length == clen
          }
        elsif clen < 0
          # puts "* no content-length information ... mmmmmpf"
          # eofcount = 0
          Watobo::HTTPSocket.read_body(socket) do |c|
            data += c
          end

        end

        response.push data unless data.empty?
        unless prefs[:ignore_logout]==true  or @session[:logout_signatures].empty?
          notify(:logout, self) if loggedOut?(response)
        end

        @sid_cache.update_sids(request.site, response) if prefs[:update_sids] == true
        return true

      rescue => e
        puts "! Could not read response"
        puts e
        # puts e.backtrace
      end

      return false
    end

    private

    #def doNtlmAuth(socket, request, ntlm_credentials)
    def wwwAuthNTLM(socket, request, ntlm_credentials)
      response_header = nil
      auth_method = "NTLM"
      begin
        head_request = request.copy         
        head_request.setMethod(:head)         
        head_request.removeBody         
        head_request.removeHeader("Content-Length")         
        data = head_request.join + "\r\n"

        socket.print data

        response_header = readHTTPHeader(socket)
        response_header.each do |line|
          if line =~ /^www-authenticat.*((Negotiate|NTLM))/i then
            #puts line
            auth_method = $1
            break
          end
          #break if line.strip.empty?
        end

        ntlm_challenge = nil
        t1 = Watobo::NTLM::Message::Type1.new()
        %w(workstation domain).each do |a|
          t1.send("#{a}=",'')
          t1.enable(a.to_sym)
        end

        msg = "#{auth_method} #{t1.encode64}"
        head_request.set_header("Authorization", msg)

        data = head_request.join + "\r\n"

        socket.print data

        response_header = []
        rcode = nil
        clen = nil
        ntlm_challenge = nil
        response_header = readHTTPHeader(socket)
        response_header.each do |line|
          if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
            rcode = $1.to_i
            rmsg = $2
          end
          if line =~ /^WWW-Authenticate: (NTLM|Negotiate) (.+)\r\n/
            ntlm_challenge = $2
          end
          if line =~ /^Content-Length: (\d{1,})\r\n/
            clen = $1.to_i
          end
          break if line.strip.empty?
        end

        if rcode == 401 #Authentication Required
          puts "[NTLM] got ntlm challenge: #{ntlm_challenge}" if $DEBUG
          return socket, response_header if ntlm_challenge.nil?
        elsif rcode == 200 # Ok
          puts "[NTLM] seems request doesn't need authentication" if $DEBUG
          return socket, Watobo::Response.new(response_header)
        else
          if $DEBUG
            puts "[NTLM] ... !#*+.!*peep* ...."
            puts response_header
          end
          return socket, Watobo::Response.new(response_header)
        end


        t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
        domain = ntlm_credentials.has_key?(:domain) ? Watobo::UTF16.encode_utf16le(ntlm_credentials[:domain].upcase) : ""
        creds = {:user => ntlm_credentials[:username],
                 :password => ntlm_credentials[:password],
                 :domain => domain,
                 :workstation => Watobo::UTF16.encode_utf16le(Socket.gethostname)
        }

        t3 = t2.response( creds,            
                         {:ntlmv2 => true}
                        )

        auth_request = request.copy

        auth_request.set_header("Connection", "close")

        msg = "#{auth_method} #{t3.encode64}"
        auth_request.set_header("Authorization", msg)
        #      puts "============= T3 ======================="

        data = auth_request.join + "\r\n"
        socket.print data

        response_header = []
        response_header = readHTTPHeader(socket)
        response_header.each do |line|

          if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
            rcode = $1.to_i
            rmsg = $2
          end
          break if line.strip.empty?
        end

        if rcode == 200 # Ok
          puts "[NTLM] Authentication Successfull" if $DEBUG
        elsif rcode == 401 # Authentication Required
          # TODO: authorization didn't work -> do some notification
          # ...
          puts "[NTLM] could not authenticate. Bad credentials?"
        end

        return socket, Watobo::Response.new(response_header)
      rescue => bang
        puts "!!! ERROR: in ntlm_auth"
        puts bang

        puts bang.backtrace if $DEBUG
        return nil, nil
      end
    end

    def sslConnect(tcp_socket, current_prefs = {} )
      begin
        #          @ctx = OpenSSL::SSL::SSLContext.new()
        #          @ctx.key = nil
        #          @ctx.cert = nil
        ctx = OpenSSL::SSL::SSLContext.new()
        ctx.ciphers = current_prefs[:ssl_cipher] if current_prefs.has_key? :ssl_cipher


        if current_prefs.has_key? :ssl_client_cert and current_prefs.has_key? :ssl_client_key

          ctx.cert = current_prefs[:ssl_client_cert]
          ctx.key = current_prefs[:ssl_client_key]
          if $DEBUG
            puts "[SSLconnect] Client Certificates"
            puts "= CERT ="
            # puts @ctx.cert.methods.sort
            puts ctx.cert.display
            puts "---"
            p
            puts "= KEY ="
            puts ctx.key.display
            puts "---"
          end                 

        end
        # @ctx.tmp_dh_callback = proc { |*args|
        #  OpenSSL::PKey::DH.new(128)
        #}
        if current_prefs.has_key? :client_certificate

          ccp = current_prefs[:client_certificate]
          ctx.cert = ccp[:ssl_client_cert]
          ctx.key = ccp[:ssl_client_key]
          ctx.extra_chain_cert = ccp[:extra_chain_certs] if ccp.has_key?(:extra_chain_certs)

          if $DEBUG
            puts "[SSLconnect] Client Certificates"
            puts "= CERT ="
            puts ctx.cert.display
            puts "---"
            p
            puts "= KEY ="
            puts ctx.key.display
            puts "---"
          end
        end

        socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)

        # need hostname for SNI (Server Name Indication)
        # http://en.wikipedia.org/wiki/Server_Name_Indication
        socket.hostname = current_prefs[:hostname] if current_prefs.has_key?(:hostname)
        socket.sync_close = true


        socket.connect
        #socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        puts "[SSLconnect]: #{socket.state}" if $DEBUG
        return socket
      rescue OpenSSL::SSL::SSLError => e
        # puts "[SSLconnect] Failure"
        # puts e      
        raise e    
        #return nil
      rescue => bang
        if current_prefs[:ssl_cipher].nil?
          puts "[SSLconnect] ... gr#!..*peep*.. "
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
    end

    # SSLProxyConnect
    # return SSLSocket, ResponseHeader of ConnectionSetup
    # On error SSLSocket is nil
    def sslProxyConnect(orig_request, proxy, prefs)
      begin
        tcp_socket = nil
        response_header = []

        request = Watobo::Utils::copyObject(orig_request)
        request.extend Watobo::Mixin::Parser::Url
        request.extend Watobo::Mixin::Parser::Web10
        request.extend Watobo::Mixin::Shaper::Web10
        #  timeout(6) do

        tcp_socket = TCPSocket.new( proxy.host, proxy.port)
        tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)    
        #tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)
        tcp_socket.sync = true
        #  end
        #  puts "* sslProxyConnect"
        #  puts "Host: #{request.host}"
        #  puts "Port: #{request.port}"
        # setup request
        dummy = "CONNECT #{request.host}:#{request.port} HTTP/1.0\r\n"
        request.shift
        request.unshift dummy

        #request.removeHeader("Proxy-Connection")
        request.removeHeader("Connection")
        request.removeHeader("Content-Length")
        request.removeBody()
        request.set_header("Proxy-Connection", "Keep-Alive")
        request.addHeader("Pragma", "no-cache")

        #  puts "=== sslProxyConnect ==="
        #  puts request

        if proxy.has_login?
          case proxy.auth_type
          when AUTH_TYPE_NTLM

            t1 = Watobo::NTLM::Message::Type1.new()
            msg = "NTLM " + t1.encode64
            request.addHeader("Proxy-Authorization", msg)

            if $DEBUG
              puts "============= PROXY NTLM: T1 ======================="
              puts request
              puts "---"
            end
            data = request.join + "\r\n"

            tcp_socket.print data
            #  puts "-----------------"
            cl = 0
            ntlm_challenge = nil
            while (line = tcp_socket.gets)
              response_header.push line
              puts line if $DEBUG
              if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
                rcode = $1.to_i
                rmsg = $2
              end
              if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
                ntlm_challenge = $2
              end
              if line =~ /^Content-Length: (\d*)/i
                cl = $1.to_i
              end
              break if line.strip.empty?
            end


            if cl > 0
              Watobo::HTTPSocket.read_body(tcp_socket) { |d|
                # puts d
              }
            end

            if rcode == 200 # Ok
              puts "* seems proxy doesn't require authentication"
              socket = sslConnect(tcp_socket, prefs)
              return socket, response_header
            end

            return socket, response_header if ntlm_challenge.nil? or ntlm_challenge == ""

            t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
            t3 = t2.response( { :user => proxy.username,
                                :password => proxy.password,
                                :domain => proxy.domain },
                                { :workstation => proxy.workstation, :ntlmv2 => true } )
            request.removeHeader("Proxy-Authorization")

            msg = "NTLM " + t3.encode64
            request.addHeader("Proxy-Authorization", msg)

            data = request.join + "\r\n"
            if $DEBUG
              puts "============= T3 ======================="
              puts data
              puts "---"
            end

            tcp_socket.print data
            #  puts "-----------------"

            response_header = []
            rcode = 0
            response_header = readHTTPHeader(tcp_socket)
            rcode = response_header.status
            if rcode =~/^200/ # Ok
              puts "[ProxyAuth-NTLM] Authorization Successful" if $DEBUG
              socket = sslConnect(tcp_socket, prefs)
              return socket, response_header
            elsif rcode =~ /^407/ # ProxyAuthentication Required
              # if rcode is still 407 authentication didn't work -> break
              msg = "NTLM-Authentication failed!"
              puts "[ProxyAuth-NTLM] #{msg}" if $DEBUG
              return nil, msg
            else
              puts "[SSLconnect] NTLM Authentication"
              puts ">  #{rcode} <"
              return nil, response_header
            end              
          end
        end # END OF PROXY AUTH

        # Start ProxyConnect Without Authentication
        data = request.join + "\r\n"
        tcp_socket.print data
        # puts "-----------------"

        response_header = []
        response_header = readHTTPHeader(tcp_socket)
        rcode = response_header.status
        if rcode =~ /^200/ # Ok
          # puts "* proxy connection successfull"
        elsif rcode =~ /^407/ # ProxyAuthentication Required
          # if rcode is still 407 authentication didn't work -> break

        else
          puts "[SSLconnect] Response Status"
          puts ">  #{rcode} <"
        end

        socket = sslConnect(tcp_socket, prefs)
        return socket, response_header
      rescue => bang
        puts bang
        puts proxy
        puts prefs
        return nil, error_response(bang)
      end
      # return nil, nil
    end

    # proxyAuthNTLM
    # returns: ResponseHeaders
    def proxyAuthNTLM(tcp_socket, orig_request, proxy)

      if orig_request.respond_to? :copy
        request = orig_request.copy
      else
        request = Watobo::Response.new YAML.load(YAML.dump(orig_request))
      end

      request.removeHeader("Proxy-Authorization")
      request.removeHeader("Proxy-Connection")

      response_header = []

      ntlm_challenge = nil
      t1 = Watobo::NTLM::Message::Type1.new()
      msg = "NTLM " + t1.encode64

      request.addHeader("Proxy-Authorization", msg)
      request.addHeader("Proxy-Connection", "Keep-Alive")

      #   puts "============= T1 ======================="
      #    puts auth_request
      data = request.join + "\r\n"

      tcp_socket.print data
      #  puts "-----------------"
      response_header = readHTTPHeader(tcp_socket)
      rcode = nil
      rmsg = nil
      ntlm_challenge = nil
      clen = 0
      response_header.each do |line|
        # puts line
        if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
          rcode = $1.to_i
          rmsg = $2
        end
        if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
          ntlm_challenge = $2
        end
        if line =~ /^Content-Length: (\d{1,})\r\n/
          clen = $1.to_i
        end
        break if line.strip.empty?
      end

      #puts "* reading #{clen} bytes"

      if rcode == 407 # ProxyAuthentication Required
        return response_header if ntlm_challenge.nil? or ntlm_challenge == ""
      else
        puts "* no proxy authentication required!"
        return response_header
      end

      Watobo::HTTPSocket.read_body(tcp_socket, :max_bytes => clen){ |d|
        #puts d
      }

      t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
      t3 = t2.response({:user => proxy.username, :password => proxy.password, :workstation => proxy.workstation, :domain => proxy.domain}, {:ntlmv2 => true})
      #request.removeHeader("Proxy-Authorization")
      #  request.removeHeader("Proxy-Connection")

      #  request.addHeader("Proxy-Connection", "Close")
      #  request.addHeader("Pragma", "no-cache")
      msg = "NTLM " + t3.encode64
      request.addHeader("Proxy-Authorization", msg)
      # puts "============= T3 ======================="
      # puts request
      # puts "------------------------"
      data = request.join + "\r\n"
      tcp_socket.print data

      response_header = readHTTPHeader(tcp_socket)
      response_header.each do |line|
        #  puts line
        if line =~ /^HTTP\/\d\.\d (\d+) (.*)/ then
          rcode = $1.to_i
          rmsg = $2
        end
        if line =~ /^Proxy-Authenticate: (NTLM) (.+)\r\n/
          ntlm_challenge = $2
        end
        if line =~ /^Content-Length: (\d{1,})\r\n/
          clen = $1.to_i
        end
        break if line.strip.empty?
      end

      return response_header
    end

    #
    # doProxyAuth
    #
    def doProxyAuth(tcp_socket, orig_request, proxy)
      case proxy.auth_type
      when AUTH_TYPE_NTLM
        return proxyAuthNTLM(tcp_socket, orig_request, proxy)

      end # END OF NTLM

    end

    ##################################################
    #    doProxyRequest
    ################################################
    def doProxyRequest(request, proxy, prefs={})

      begin
        tcp_socket = nil
        site = request.site

        auth_request = Watobo::Utils::copyObject(request)
        auth_request.extend Watobo::Mixin::Parser::Url
        auth_request.extend Watobo::Mixin::Parser::Web10
        auth_request.extend Watobo::Mixin::Shaper::Web10
        #  timeout(6) do

        tcp_socket = TCPSocket.new( proxy.host, proxy.port)
        tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        tcp_socket.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR, true)    
        tcp_socket.sync = true
        #  end

        auth_request.removeHeader("Proxy-Connection")
        auth_request.removeHeader("Connection")

        auth_request.addHeader("Pragma", "no-cache")

        if proxy.has_login?
          response_header = doProxyAuth(tcp_socket, auth_request, proxy)
          # puts "* got request_header from doProxy Auth"
          # puts request_header.class
          puts "[Proxy Auth] Status: #{response_header.status}" if $DEBUG
          return tcp_socket, response_header unless response_header.status =~ /401/
          return tcp_socket, response_header unless prefs[:www_auth].has_key?(site)
        end

        #    puts "CHECK WWW_AUTH"
        #    puts prefs.to_yaml
        if prefs[:www_auth].has_key?(site)
          case prefs[:www_auth][site][:type]
          when AUTH_TYPE_NTLM
            # puts "* found NTLM credentials for site #{site}"
            socket, response_header = wwwAuthNTLM(tcp_socket, request, prefs[:www_auth][site])

            #response_header.extend Watobo::Mixin::Parser::Url
            #response_header.extend Watobo::Mixin::Parser::Web10
            return socket, response_header
          else
            puts "* Unknown Authentication Type: #{prefs[:www_auth][site][:type]}"
          end
        else
          data = auth_request.join + "\r\n"

          tcp_socket.print data

          response_header = readHTTPHeader(tcp_socket)
          return tcp_socket, response_header
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG

      end
      return nil
    end

    def loggedOut?(response, prefs={})
      begin
        return false if @session[:logout_signatures].empty?
        response.each do |line|
          @session[:logout_signatures].each do |p|
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

    def error_response(msg, comment=nil)
      er = []
      er << "HTTP/1.1 555 Watobo Error\r\n"
      #er << "WATOBO: #{msg.gsub(/\r?\n/," ").strip}\r\n"
      er << "WATOBO: Error\r\n"
      er << "Date: #{Time.now.to_s}\r\n"
      er << "Content-Length: 0\r\n"
      er << "Content-Type: text/html\r\n"
      er << "Connection: close\r\n"
      er << "\r\n"
      unless comment.nil?
        body = "<html><head><title>Watobo Error</title></head><body><H1>#{msg}</H1></br><H2>#{comment.gsub(/\r?\n/,"</br>")}</H2></body></html>" 
        er << body
      end
      er.extend Watobo::Mixin::Parser::Url
      er.extend Watobo::Mixin::Parser::Web10
      er.extend Watobo::Mixin::Shaper::Web10
      er.fix_content_length
      er
    end

    def readHTTPHeader(socket, prefs={})

      header = []
      msg = nil
      begin

        Watobo::HTTPSocket.read_header(socket) do |line|
          # puts line
          # puts line.unpack("H*")
          header.push line
        end
      rescue Errno::ECONNRESET
        msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Connection Reset By Peer</body></html>"           
      rescue Timeout::Error
        msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Timeout</body></html>"
      rescue => bang
        puts "!ERROR: read_header"
        return nil
      end

      unless msg.nil?
        header = [ "HTTP/1.1 502 Bad Gateway\r\n"]
        header <<  "Server: WATOBO\r\n"
        header << "Date: #{Time.now.to_s}\r\n"
        header << "Content-Length: #{msg.length.to_i}\r\n"
        header << "Content-Type: text/html\r\n"
        header <<  "\r\n"
        header << "#{msg}"
      end

      response = Watobo::Response.new header
      #  update_sids(header)

      #  update_sids(request.site, response) if prefs[:update_sids] == true

      unless prefs[:ignore_logout] == true or @session[:logout_signatures].empty?
        notify(:logout, self) if loggedOut?(response)
      end

      return response
    end


    def closeSocket(socket)
      return false if socket.nil?
      begin
        if socket.respond_to? :sysclose
          socket.sysclose
        elsif socket.respond_to? :shutdown
          socket.shutdown(2)
        elsif socket.respond_to? :close
          socket.close
        end
        return true 
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      false
    end

    def updateSessionSettings(settings={})
      [
        :ssl_client_cert,
        :ssl_client_key,
        :ssl_client_pass,
        :csrf_requests,
        :valid_sids,
        :sid_patterns,
        :logout_signatures,
        :logout_content_types,
        :update_valid_sids,
        :update_sids,
        :update_session,
        :update_contentlength,
        :login_chats,
        :follow_redirect
      ].each do |k|
        @session[k] = settings[k] if settings.has_key? k
      end
    end



    # this function updates specific patterns of a request, e.g. CSRF Tokens
    # Parameters:
    # request - the request which has to be updated
    # cache - the value store of already collected key-value-pairs
    # patterns - pattern expressions, similar to session-id-patterns, e.g.  /name="(sessid)" value="([0-9a-zA-Z!-]*)"/
    def updateRequestPattern(request, cache, patterns)

      request.map!{ |line|
        res = line
        patterns.each do |pat|
          begin
            if line =~ /#{pat}/i then
              pattern_key = Regexp.quote($1.upcase)
              old_value = Regexp.quote($2)
              if cache.has_key?(sid_key) then
                if not old_value =~ /#{cache[sid_key]}/ then # sid value has changed and needs update
                  #      print "S"
                  #    puts "+ update sid #{sid_key}"
                  #    puts "-OLD: #{old_value}"
                  #    puts "-NEW: #{@session[:valid_sids][request.site][sid_key]}"

                  #      puts "---"
                  # dummy = Regexp.quote(old_value)
                  res = line.gsub!(/#{old_value}/, cache[sid_key])
                  if not res then puts "!!!could not update sid (#{sid_key})"; end
                  #     puts "->#{line}"
                end
              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            # puts @session.to_yaml
          end
        end
        res
      }
    end

    def applySessionSettings(prefs)
      [ :update_valid_sids, :update_session, :update_contentlength, :valid_sids, :sid_patterns, :logout_signatures ].each do |v|
        @@settings[v] = prefs[v] if prefs[v]
      end
    end

  end
end
