# @private 
module Watobo#:nodoc: all
  module HTTPSocket
    class Connection_UNUSED

      include Watobo::Constants
      extend Watobo::Subscriber
      
      
      
      def initialize(request, prefs)
        @request = request
        @response = nil
        
        @proxy = Watobo::ForwardingProxy.get(site)

          unless @proxy.nil?
            host = @proxy.host
            port = @proxy.port
          else
            host = @request.host
            port = @request.port
          end
          # check if hostname is valid and can be resolved
          #hostip = IPSocket.getaddress(host)
        
      end
      
      def read_body( prefs={} )
        clen = @response.content_length
        data = ""
      
        begin
          if @response.is_chunked?
            Watobo::HTTPSocket.readChunkedBody(@socket) { |c|
              data += c
            }
          elsif  clen > 0
            #  puts "* read #{clen} bytes for body"
            Watobo::HTTPSocket.read_body(@socket, :max_bytes => clen) { |c|
              data += c
              break if data.length == clen
            }
          elsif clen < 0
            # puts "* no content-length information ... mmmmmpf"
           # eofcount = 0
            Watobo::HTTPSocket.read_body(@socket) do |c|
              data += c
            end

          end
          
          response.push data unless data.empty?
          unless prefs[:ignore_logout]==true  or @session[:logout_signatures].empty?
            notify(:logout, self) if loggedOut?(response)
          end

          update_sids(request.host, response) if prefs[:update_sids] == true
          return true
   
        rescue => e
          puts "! Could not read response"
          puts e
          # puts e.backtrace
        end

        return false
      end
      
      def read_header( prefs={} )
        
        header = []
        msg = nil
        begin
            Watobo::HTTPSocket.read_header(@socket) do |line|
            #puts line
            # puts line.unpack("H*")
            header << line
          end
          rescue Errno::ECONNRESET
            msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Connection Reset By Peer</body></html>"           
          rescue Timeout::Error
            msg = "<html><head><title>WATOBO</title></head><body>WATOBO: Timeout</body></html>"
        rescue => bang
          puts "!ERROR: read_header"
          return nil
        end
         
         header = [ "HTTP/1.1 502 Bad Gateway\r\n", "Server: WATOBO\r\n", "Content-Length: #{msg.length.to_i}\r\n", "Content-Type: text/html\r\n", "\r\n", "#{msg}" ] unless msg.nil?

        response = Watobo::Response.new header
        #  update_sids(header)

        #  update_sids(request.site, response) if prefs[:update_sids] == true

        unless prefs[:ignore_logout]==true or @session[:logout_signatures].empty?
           notify(:logout, self) if loggedOut?(response)
        end

        return response
      end
      
       def sslConnect(tcp_socket, current_prefs = {} )
        begin
        
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
                        puts "= KEY ="
                        puts ctx.key.display
                        puts "---"
                      end    
                      end
          
          @socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)
          @socket.sync_close = true

          @socket.connect
          @socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          puts "[SSLconnect]: #{@socket.state}" if $DEBUG
          return socket
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
      def sslProxyConnect( prefs )
        begin
          tcp_socket = nil
          response_header = []

          request = @request.copy
         
          #  timeout(6) do

          tcp_socket = TCPSocket.new( @proxy.host, @proxy.port)
          tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          tcp_socket.sync = true
         
          # setup request
          dummy = "CONNECT #{request.host}:#{request.port} HTTP/1.0\r\n"
          request.shift
          request.unshift dummy

          request.removeHeader("Proxy-Connection")
          request.removeHeader("Connection")
          request.removeHeader("Content-Length")
          request.removeBody()
          request.addHeader("Proxy-Connection", "Keep-Alive")
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
              response_header = read_header(@socket)
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
          response_header = readHTTPHeader(@socket)
          rcode = response_header.status
          if rcode =~ /^200/ # Ok
            # puts "* proxy connection successfull"
          elsif rcode =~ /^407/ # ProxyAuthentication Required
            # if rcode is still 407 authentication didn't work -> break

          else
            puts "[SSLconnect] Response Status"
            puts ">  #{rcode} <"
          end

          socket = sslConnect(@socket, prefs)
          return socket, response_header
        rescue => bang
          puts bang
          return nil, error_response(bang)
        end
        # return nil, nil
      end

      # proxyAuthNTLM
      # returns: ResponseHeaders
      def proxyAuthNTLM()
        
        request = @request.copy
        
        
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

        @socket.print data
        #  puts "-----------------"
        response_header = readHTTPHeader(@socket)
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

        Watobo::HTTPSocket.read_body(@socket, :max_bytes => clen){ |d|
          #puts d
        }

        t2 = Watobo::NTLM::Message.decode64(ntlm_challenge)
        t3 = t2.response({:user => proxy.username, :password => proxy.password, :workstation => proxy.workstation, :domain => proxy.domain}, {:ntlmv2 => true})
        request.removeHeader("Proxy-Authorization")
        #  request.removeHeader("Proxy-Connection")

        #  request.addHeader("Proxy-Connection", "Close")
        #  request.addHeader("Pragma", "no-cache")
        msg = "NTLM " + t3.encode64
        request.addHeader("Proxy-Authorization", msg)
        # puts "============= T3 ======================="
        # puts request
        # puts "------------------------"
        data = request.join + "\r\n"
        @socket.print data

        response_header = readHTTPHeader(@socket)
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
        #  Watobo::HTTPSocket.read_body(tcp_socket, :max_bytes => clen){ |d|
        #puts d
        #  }
        return response_header
      end

      #
      # doProxyAuth
      #
      def  doProxyAuth()
       # puts "DO PROXY AUTH"
       # puts proxy.to_yaml
        response_headers = nil
        case @proxy.auth_type
        when AUTH_TYPE_NTLM
          return proxyAuthNTLM()

        end # END OF NTLM

      end

      
    end
  end
end
