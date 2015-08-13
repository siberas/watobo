# @private 
module Watobo#:nodoc: all
  module HTTPSocket
    class Agent_UNUSED     

      include Watobo::Constants
      extend Watobo::Subscriber  

      
      def runLogin(chat_list, prefs={})
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
                print "! LoginRequest: #{chat.id}" if $DEBUG
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
            # exit
            #  print "L]"
          end
        end
      end
      
      def connected?
        !@connection.nil?
      end
      
      

     

      # sendHTTPRequest
      def send(request, prefs={})
#Watobo.print_debug("huhule", "#{prefs.to_yaml}", "gagagag")
        begin
          @lasterror = nil
          response_header = nil
          
         
          # update current preferences, prefs given here are stronger then global settings!
          current_prefs = Hash.new
          [:update_session, :update_sids, :update_contentlength, :ssl_cipher, :www_auth, :client_certificates].each do |k|
            current_prefs[k] = prefs[k].nil? ? @session[k] : prefs[k]
          end

          updateSession(request) if current_prefs[:update_session] == true

          #---------------------------------------
          request.removeHeader("^Proxy-Connection") #if not use_proxy
          #request.removeHeader("^Connection") #if not use_proxy
          request.removeHeader("^Accept-Encoding")
          # If-Modified-Since: Tue, 28 Oct 2008 11:06:43 GMT
          # If-None-Match: W/"3975-1225192003000"
          request.removeHeader("^If-")
          #  puts
          #  request.each do |line|
          #  puts line.unpack("H*")
          #end
          #puts
          if current_prefs[:update_contentlength] == true then
            request.fix_content_length()
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
              return socket, request, response_header
            end
            #  puts "* doProxyRequest"
            socket, response_header = doProxyRequest(request, proxy, current_prefs)
            #   puts socket.class
            return socket, response_header, error_response("Could Not Connect To Proxy: #{proxy.name} (#{proxy.host}:#{proxy.port})\n", "#{response_header}") if socket.nil?

            return socket, request, response_header
          else
            # direct connection to host
            tcp_socket = nil
            #  timeout(6) do
            #puts "* no proxy - direct connection"
            tcp_socket = TCPSocket.new( host, port )
            tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
            tcp_socket.sync = true

            socket =  tcp_socket
            if request.is_ssl?
              ssl_prefs = {}
              ssl_prefs[:ssl_cipher] = current_prefs[:ssl_cipher] if current_prefs.has_key? :ssl_cipher
              if current_prefs.has_key? :client_certificates
                if current_prefs[:client_certificates].has_key? request.site
                  puts "* use ssl client certificate for site #{request.site}" if $DEBUG
                  ssl_prefs[:ssl_client_cert] = current_prefs[:client_certificates][request.site][:ssl_client_cert] 
                ssl_prefs[:ssl_client_key] = current_prefs[:client_certificates][request.site][:ssl_client_key]
                end
              end
              socket = sslConnect(tcp_socket, ssl_prefs)
            end
            #puts socket.class
            # remove URI before sending request but cache it for restoring request
            uri_cache = nil
            uri_cache = request.removeURI #if proxy.nil?

            
           # request.addHeader("Proxy-Connection", "Close") unless proxy.nil?
           # request.addHeader("Accept-Encoding", "gzip;q=0;identity; q=0.5, *;q=0") #don't want encoding
            

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
             # request.addHeader("Connection", "Close") #if not use_proxy

              data = request.join
              unless request.has_body? 
                data << "\r\n" unless data =~ /\r\n\r\n$/ 
              end
             # puts "= SESSION ="
             # puts data
             # puts data.unpack("H*")[0].gsub(/0d0a/,"0d0a\n")
              
              unless socket.nil?                
                socket.print data
               # if socket.is_a? OpenSSL::SSL::SSLSocket
               #   socket.io.shutdown(Socket::SHUT_WR)
               # else
               #   socket.shutdown(Socket::SHUT_WR)
               # end
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
          response = error_response "TimeOut (#{host}:#{port})"
          socket = nil
        rescue Errno::ENOTCONN
          puts "!!!ENOTCONN"
        rescue OpenSSL::SSL::SSLError
          response = error_response "SSL-Error", $!.backtrace.join
          socket = nil
        rescue => bang
          response = error_response "ERROR:", "#{bang}\n#{bang.backtrace}"
          socket = nil

          puts bang
          puts bang.backtrace if $DEBUG
        end
        puts response
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
          @session.update opts
        #  puts "[doRequest] #{@session.to_yaml}"
          # puts "#[#{self.class}]" + @session[:csrf_requests].first.object_id.to_s
          unless @session[:csrf_requests].empty? or @session[:csrf_patterns].empty?
            csrf_cache = Hash.new
            @session[:csrf_requests].each do |req|
              copy = Watobo::Request.new YAML.load(YAML.dump(req))

              updateCSRFToken(csrf_cache, copy)
              socket, csrf_request, csrf_response = sendHTTPRequest(copy, opts)
              next if socket.nil?
            #  puts "= Response Headers:"
            #  puts csrf_response
            #  puts "==="
              update_sids(csrf_request.host, csrf_response.headers)
              next if socket.nil?
              #  p "*"
              #    csrf_response = readHTTPHeader(socket)
              readHTTPBody(socket, csrf_response, csrf_request, opts)

              next if csrf_response.body.nil?
              update_sids(csrf_request.host, [csrf_response.body])

              updateCSRFCache(csrf_cache, csrf_request, [csrf_response.body]) if csrf_response.content_type =~ /text\//

              # socket.close
              closeSocket(socket)
            end
            #p @session[:csrf_requests].length
            updateCSRFToken(csrf_cache, request)
          end

          socket, request, response = sendHTTPRequest(request, opts)

          if socket.nil?
            return request, response
          end

          update_sids(request.host, response.headers) if @session[:update_sids] == true
          
          if @session[:follow_redirect]
 # puts response.status
  if response.status =~ /^302/
    response.extend Watobo::Mixin::Parser::Web10
    request.extend Watobo::Mixin::Shaper::Web10

    loc_header = response.headers("Location:").first
    new_location = loc_header.gsub(/^[^:]*:/,'').strip
    unless new_location =~ /^http/
      new_location = request.proto + "://" + request.site + "/" + request.dir + "/" + new_location.sub(/^[\.\/]*/,'')
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
            update_sids(request.host, [response.body]) if @session[:update_sids] == true and response.content_type =~ /text\//
          end

          #socket.close
          closeSocket(socket)

        rescue  => bang
          #  puts "! Error in doRequest"
          puts "! Module #{Module.nesting[0].name}"
          puts bang
          #  puts bang.backtrace if $DEBUG
          @lasterror = bang
          # raise
          # ensure
        end

        response.extend Watobo::Mixin::Parser::Web10
        return request, response
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
      def initialize( session_id, prefs={} )
        
        @connection = nil

        session = nil

        session = ( session_id.is_a? Fixnum ) ? session_id : session_id.object_id
        session = Digest::MD5.hexdigest(Time.now.to_f.to_s) if session_id.nil?

        unless @@settings.has_key? session
          @@settings[session] = {
            :valid_sids => Hash.new,
            :sid_patterns => [],
            # :valid_csrf_tokens => Hash.new,
            :csrf_patterns => [],
            :csrf_requests => [],
            :logout_signatures => [],
            :logout_content_types => Hash.new,
            :update_valid_sids => false,
            :update_sids => false,
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

        @ctx = OpenSSL::SSL::SSLContext.new()
        @ctx.key = nil
        @ctx.cert = nil

        # TODO: Implement switches for URL-Encoding (http://www.blooberry.com/indexdot/html/topics/urlencoding.htm)
        # TODO: Implement switches for Following Redirects
        # TODO: Implement switches for Logging, Debugging, ...
      end

      

      private

      #def doNtlmAuth(socket, request, ntlm_credentials)
      def wwwAuthNTLM(socket, request, ntlm_credentials)
        response_header = nil
        begin
          auth_request = request.copy

          ntlm_challenge = nil
          t1 = Watobo::NTLM::Message::Type1.new()
          msg = "NTLM " + t1.encode64

          auth_request.removeHeader("Connection")
          auth_request.removeHeader("Authorization")

          auth_request.addHeader("Authorization", msg)
          auth_request.addHeader("Connection", "Keep-Alive")

          if $DEBUG
            puts "============= T1 ======================="
            puts auth_request
      end
          
          data = auth_request.join + "\r\n"
          socket.print data
          
      puts "-----------------" if $DEBUG
      
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
            if line =~ /^WWW-Authenticate: (NTLM) (.+)\r\n/
              ntlm_challenge = $2
            end
            if line =~ /^Content-Length: (\d{1,})\r\n/
              clen = $1.to_i
            end
            break if line.strip.empty?
          end
          #        puts "==================="

      if $DEBUG
        puts "--- T1 RESPONSE HEADERS ---"
        puts response_header
      puts "---"
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

          # reading rest of response
      rest = ''
          Watobo::HTTPSocket.read_body(socket, :max_bytes => clen){ |d| 
         rest += d
      }

      if $DEBUG
      puts "--- T1 RESPONSE BODY ---"
      puts rest
      puts "---"
      end
          t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
          t3 = t2.response({:user => ntlm_credentials[:username],
            :password => ntlm_credentials[:password],
            :domain => ntlm_credentials[:domain]},
          {:workstation => ntlm_credentials[:workstation], :ntlmv2 => true})

          #     puts "* NTLM-Credentials: #{ntlm_credentials[:username]},#{ntlm_credentials[:password]}, #{ntlm_credentials[:domain]}, #{ntlm_credentials[:workstation]}"
          auth_request.removeHeader("Authorization")
          auth_request.removeHeader("Connection")

          auth_request.addHeader("Connection", "Close")

          msg = "NTLM " + t3.encode64
          auth_request.addHeader("Authorization", msg)
          #      puts "============= T3 ======================="

          data = auth_request.join + "\r\n"

          if $DEBUG
            puts "= NTLM Type 3 ="
            puts data
          end
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
            puts ntlm_credentials.to_yaml
          end

          return socket, Watobo::Response.new(response_header)
        rescue => bang
          puts "!!! ERROR: in ntlm_auth"
          puts bang

          puts bang.backtrace if $DEBUG
          return nil, nil
        end
      end

     
      ##################################################
      #    doProxyRequest
      ################################################
      def doProxyRequest(request, proxy, prefs={})
        #puts "DO PROXY REQUEST"
        # puts prefs.to_yaml
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
      er << "WATOBO: #{msg.gsub(/\r?\n/," ").strip}\r\n"
      er << "Content-Length: 0\r\n"
      er << "Connection: close\r\n"
      er << "\r\n"
      unless comment.nil?
      body = "<H1>#{msg}</H1></br><H2>#{comment.gsub(/\r?\n/,"</br>")}</H2>" 
      er << body
      end
       er.extend Watobo::Mixin::Parser::Url
        er.extend Watobo::Mixin::Parser::Web10
        er.extend Watobo::Mixin::Shaper::Web10
        er.fix_content_length
        er
      end
      
      

      #     def read_response(socket)

      #       return response
      #    end

     
      def updateCSRFCache(csrf_cache, request, response)
         puts "=UPDATE CSRF CACHE" if $DEBUG
        # Thread.new{
        begin
          #   site = request.site
          @@csrf_lock.synchronize do
            response.each do |line|
              # puts line
              @session[:csrf_patterns].each do |pat|
                puts pat if $DEBUG
                if line =~ /#{pat}/i then
                  token_key = Regexp.quote($1.upcase)
                  token_value = $2
                  #print "U"
                    puts "GOT NEW TOKEN (#{token_key}): #{token_value}" if $DEBUG
                  #   @session[:valid_csrf_tokens][site] = Hash.new if @session[:valid_csrf_tokens][site].nil?
                  #   @session[:valid_csrf_tokens][site][token_key] = token_value
                  csrf_cache[token_key] = token_value
                end
              end

            end
          end
        rescue => bang
          puts bang
          if $DEBUG
          puts bang.backtrace 
          puts "= Request"
          puts request 
          puts "= Response"
          puts response
          puts "==="
          end

        end
        # }
      end

      def closeSocket(socket)
      return false if socket.nil?
      begin
        if socket.respond_to? :sysclose
        #socket.io.shutdown(2)
      #  puts "sysclose"
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

      

      def updateCSRFToken(csrf_cache, request)
        # puts "=UPDATE CSRF TOKEN"
        # @session[:valid_csrf_tokens].to_yaml
        # puts request if request.site.nil?
        # puts "= = = = = = "
        @@csrf_lock.synchronize do
          #  if @session[:valid_csrf_tokens].has_key?(request.site)
          #    puts "* found token for site: #{request.site}"

          request.map!{ |line|
            res = line
            @session[:csrf_patterns].each do |pat|
              begin
                if line =~ /#{pat}/i then
                  key = Regexp.quote($1.upcase)
                  old_value = $2
                  if csrf_cache.has_key?(key) then
                    res = line.gsub!(/#{Regexp.quote(old_value)}/, csrf_cache[key])
                    if res.nil? then
                      res = line
                      puts "!!!could not update token (#{key})"
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
        # end
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
end