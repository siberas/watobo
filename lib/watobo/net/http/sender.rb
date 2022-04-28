require 'net/protocol'

module Watobo
  module Net
    module Http
      class Sender < ::Net::Protocol

        include Net

        DEFAULT_PREFS = {
            :www_auth => Hash.new,
            :client_certificate => {},
            :ssl_cipher => nil,
            :proxy => nil,
            # user and pass for Basic Auth
            :username => nil,
            :password => nil,
            :timeout => 60,
            :write_timeout => 60
        }

        def proxy?
          !@proxy.nil?
        end

        def is_ssl?
          @request.is_ssl?
        end

        def env_proxy?
          !ENV['WATOBO_PROXY'].nil?
        end

        def env_proxy
          return nil unless ENV['WATOBO_PROXY']
          uri = URI.parse ENV['WATOBO_PROXY']
          ps = {
              name: 'env',
              host: uri.host,
              port: uri.port
          }
          Proxy.new ps
        end


        def initialize(request, prefs = {})
          @socket = nil
          @ctx = OpenSSL::SSL::SSLContext.new()
          @ctx.key = nil
          @ctx.cert = nil
          @request = request

          @prefs = {}
          DEFAULT_PREFS.keys.each do |pk|
            @prefs[pk] = prefs.has_key?(pk) ? prefs[pk] : DEFAULT_PREFS[pk]
          end

          @read_timeout = @prefs[:timeout]
          @write_timeout = @prefs[:write_timeout]

          @proxy = !!@prefs[:proxy] ? Proxy.new(@prefs[:proxy]) : nil

          # set/overwrite proxy if set by environent WATOBO_PROXY
          @proxy = env_proxy if env_proxy?

        end

        def exec
          request = nil
          #response = nil
          t_start = Process.clock_gettime(Process::CLOCK_REALTIME)
          t_end = nil
          error = nil
          begin
            socket = connect
            request = send(socket, @request)

            header = read_header(socket)

            response = read_body(socket, header)
            t_end = Process.clock_gettime(Process::CLOCK_REALTIME)

            socket.close

            response.unzip!

          rescue Net::ReadTimeout
            t_end = Process.clock_gettime(Process::CLOCK_REALTIME)

          rescue => bang
            response = error_response bang
            error = bang
            if $DEBUG
              puts bang.backtrace
              binding.pry
            end
          end
          #puts response
          meta = {
              t_start: t_start,
              t_end: t_end,
              duration: (t_end ? (t_end - t_start) : nil),
              error: error
          }

          response.update_meta meta
          return request, response
        end

        private


        def connect_proxy


          host = @request.host
          port = @request.port

          proxy_ip = IPSocket.getaddress(host)

          s = Socket.tcp proxy_ip, proxy_port, nil, nil, connect_timeout: @open_timeout
          s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
          plain_sock = BufferedIO.new(s, read_timeout: @read_timeout,
                                      write_timeout: @write_timeout,
                                      continue_timeout: @continue_timeout,
                                      debug_output: @debug_output)
          buf = "CONNECT #{host}:#{port} HTTP/#{HTTPVersion}\r\n"
          buf << "Host: #{host}:#{port}\r\n"
          #if proxy_user
          #           credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
          #           buf << "Proxy-Authorization: Basic #{credential}\r\n"
          #         end
          buf << "\r\n"
          plain_sock.write(buf)
          HTTPResponse.read_new(plain_sock).value
          # assuming nothing left in buffers after successful CONNECT response

        end


        def send(sock, request)
          # remove URI before sending request but cache it for restoring request
          uri_cache = request.removeURI unless proxy?
          data = request.join

          unless request.has_body?
            data << "\r\n" unless data =~ /\r\n\r\n$/
          end

          sock.write data

          request.restoreURI(uri_cache) unless proxy?

          request
        end


        def read_header(sock)
          h = []
          # read first response line and add CRLF because .readline removed it
          h << sock.readline + "\r\n"
          while true
            line = sock.readuntil("\n", true) #.sub(/\s+\z/, '')
            h << line
            break if line.empty?
          end
          Watobo::Response.new(h)
        end


        def read_body(sock, response)
          clen = response.content_length

          begin
            if response.is_chunked?
              body = read_chunked(sock)
              response.set_body body
              response.removeHeader("Transfer-Encoding")
              response.set_header("Content-Length", "#{body.length}")
            elsif clen > 0
              body = ''
              sock.read clen, body
              response.set_body body
              response.set_header("Content-Length", "#{body.length}")
            elsif clen < 0

            end

          rescue EOFError
            # ignore
          rescue => e
            raise e
          end

          response
        end

        def connect
          if proxy?
            conn_host = @proxy.host
            conn_port = @proxy.port
          else
            conn_host = @request.host
            conn_port = @request.port
          end

          conn_ip = IPSocket.getaddress(conn_host)

          s = Socket.tcp conn_ip, conn_port, nil, nil, connect_timeout: @open_timeout
          s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          if is_ssl?

            if proxy?
              plain_sock = ::Net::BufferedIO.new(s, read_timeout: @read_timeout,
                                                 write_timeout: @write_timeout,
                                                 continue_timeout: @continue_timeout,
                                                 debug_output: @debug_output)
              buf = "CONNECT #{@request.host}:#{@request.port} HTTP/#{1.1}\r\n"
              buf << "Host: #{@request.host}:#{@request.port}\r\n"
              #if proxy_user
              #  credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
              #  buf << "Proxy-Authorization: Basic #{credential}\r\n"
              #end
              buf << "\r\n"
              plain_sock.write(buf)

              ph = read_header(plain_sock)
              # assuming nothing left in buffers after successful CONNECT response
            end

            @ssl_context = ssl_context

            unless @ssl_context.session_cache_mode.nil? # a dummy method on JRuby
              @ssl_context.session_cache_mode =
                  OpenSSL::SSL::SSLContext::SESSION_CACHE_CLIENT |
                      OpenSSL::SSL::SSLContext::SESSION_CACHE_NO_INTERNAL_STORE
            end
            if @ssl_context.respond_to?(:session_new_cb) # not implemented under JRuby
              @ssl_context.session_new_cb = proc { |sock, sess| @ssl_session = sess }
            end

            s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
            s.sync_close = true
            # need hostname for SNI (Server Name Indication)
            # http://en.wikipedia.org/wiki/Server_Name_Indication
            s.hostname = @request.host #if s.respond_to?(:hostname=) && ssl_host_address

            if @ssl_session and
                Process.clock_gettime(Process::CLOCK_REALTIME) < @ssl_session.time.to_f + @ssl_session.timeout
              s.session = @ssl_session
            end

            ssl_socket_connect(s, @open_timeout)

            if (@ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE) && verify_hostname
              s.post_connection_check(@address)
            end
            # debug "SSL established, protocol: #{s.ssl_version}, cipher: #{s.cipher[0]}"
          end
          @socket = ::Net::BufferedIO.new(s, read_timeout: @read_timeout,
                                          write_timeout: @write_timeout,
                                          continue_timeout: @continue_timeout,
                                          debug_output: @debug_output)
          @socket
        end

        def error_response(error)
          er = []
          er << "HTTP/1.1 555 Watobo Error\r\n"
          er << "WATOBO-MSG: #{Base64.strict_encode64(error.to_s)}"
          er << "Date: #{Time.now.to_s}\r\n"
          er << "Content-Length: 0\r\n"
          er << "Content-Type: text/html\r\n"
          er << "Connection: close\r\n"
          er << "\r\n"
          er << "<html><head><title>Watobo Error</title></head><body><H1>#{error.to_s}</H1></br><H2>#{error.backtrace.to_s.gsub(/\r?\n/, "</br>")}</H2></body></html>"

          res = Watobo::Response.new er
          res.fix_content_length
          res
        end

        def ssl_context
          ctx = OpenSSL::SSL::SSLContext.new()
          ctx.ciphers = @prefs[:ssl_cipher] if !!@prefs[:ssl_cipher]
          if !!@prefs[:client_certificate]
            ccp = @prefs[:client_certificate]
            ctx.cert = ccp[:ssl_client_cert]
            ctx.key = ccp[:ssl_client_key]
            ctx.extra_chain_cert = ccp[:extra_chain_certs] if ccp.has_key?(:extra_chain_certs)
          end
          ctx
        end

        def read_chunked(sock)
          total = 0
          data = ''
          while true
            line = sock.readline
            #next if line.strip.empty?
            hexlen = line.slice(/[0-9a-fA-F]+/) or raise "wrong chunk size line: #{line}"
            len = hexlen.hex
            break if len == 0
            begin
              sock.read len, data
            ensure
              total += len
              sock.read 2 # \r\n
            end
          end
          until sock.readline.empty?
            # none
          end
          data
        end

      end
    end
  end

end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", '..'))
  puts inc_path
  $: << inc_path

  require 'watobo'

  prefs = {timeout: 10}
  req = Watobo::Request.new ARGV[0]
  sender = Watobo::Net::Http::Sender.new req, prefs
  req, res = sender.exec
  puts res
  puts '-- META ---'
  puts res.meta.to_json

end