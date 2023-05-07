require 'net/protocol'

module Watobo
  module Net
    module Http
      class Sender < ::Net::Protocol
        attr_accessor :sni_host

        include Net

        DEFAULT_PREFS = {
          :www_auth => Hash.new,
          :client_certificate => {},
          :ssl_cipher => nil,
          :proxy => nil, # { host: 1.2.3.4, port: 8080, name: 'some name'}
          # user and pass for Basic Auth
          :username => nil,
          :password => nil,
          :sni_host => nil,
          :timeout => 60,
          :write_timeout => 60,
          :open_timeout => 10
        }

        def proxy?
          !@proxy.nil?
        end

        # def is_ssl?
        #  @request.is_ssl?
        # end

        def env_proxy?
          !ENV['WATOBO_PROXY'].nil?
        end

        def env_proxy
          return nil unless ENV['WATOBO_PROXY']
          uri = URI.parse ENV['WATOBO_PROXY']
          return nil unless uri.host
          return nil unless uri.port
          ps = {
            name: 'env',
            host: uri.host,
            port: uri.port
          }
          Proxy.new ps
        end

        def on_header(&block)
          @on_header_cb = block
        end

        def on_ssl_connect(&block)
          @on_ssl_connect_cb = block
        end

        # def initialize(request, prefs = {})
        def initialize(prefs = {})
          @socket = nil
          @ctx = OpenSSL::SSL::SSLContext.new()
          @ctx.key = nil
          @ctx.cert = nil
          #@request = request.is_a?(String) ? Watobo::Request.new(request) : request

          @prefs = {}
          DEFAULT_PREFS.keys.each do |pk|
            @prefs[pk] = prefs.has_key?(pk) ? prefs[pk] : DEFAULT_PREFS[pk]
          end
          @sni_host = prefs[:sni_host]

          @read_timeout = @prefs[:timeout]
          @write_timeout = @prefs[:write_timeout]
          @open_timeout = @prefs[:open_timeout]

          @proxy = !!@prefs[:proxy] ? Proxy.new(@prefs[:proxy]) : nil

          # set/overwrite proxy if set by environent WATOBO_PROXY
          @proxy = env_proxy if env_proxy?

          @on_header_cb = nil
          @on_ssl_connect_cb = nil

        end

        def exec(request)
          # request = nil
          # response = nil
          t_start = Process.clock_gettime(Process::CLOCK_REALTIME)
          t_end = nil
          error = nil
          begin
            # socket = connect
            # request = send_request(socket, request)
            socket = send_request(request)
            header = read_header(socket)

            return [request, nil] unless header

            do_header header

            response = read_body(socket, header)

            # TODO: read extra body, maybe there might be some additional data on socket after reading only content-length
            # ????
            #
            t_end = Process.clock_gettime(Process::CLOCK_REALTIME)

            socket.close

            response.unzip!

          rescue ::Net::ReadTimeout => bang
            t_end = Process.clock_gettime(Process::CLOCK_REALTIME)
            response = error_response bang unless response
          rescue OpenSSL::SSL::SSLError => e
            unless header
              response = error_response e
            else
              response = header
            end
          rescue => bang
            response = error_response bang
            error = bang
            if $DEBUG
              puts bang.backtrace
              # binding.pry
            end
          end
          # puts response
          meta = {
            t_start: t_start,
            t_end: t_end,
            duration: (t_end ? (t_end - t_start) : nil),
            error: error
          }

          response.update_meta meta if response

          return request, response
        end

        private

        # callback
        def do_header(header)
          @on_header_cb.call(header) if @on_header_cb
        end

        def do_ssl_connect(sock)
          @on_ssl_connect_cb.call(sock) if @on_ssl_connect_cb
        end

        def connect_proxy
          host = @proxy.host
          port = @proxy.port

          proxy_ip = IPSocket.getaddress(host)

          s = Socket.tcp proxy_ip, proxy_port, nil, nil, connect_timeout: @open_timeout
          s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
          plain_sock = BufferedIO.new(s, read_timeout: @read_timeout,
                                      write_timeout: @write_timeout,
                                      continue_timeout: @continue_timeout,
                                      debug_output: @debug_output)
          buf = "CONNECT #{host}:#{port} HTTP/#{HTTPVersion}\r\n"
          buf << "Host: #{host}:#{port}\r\n"
          # if proxy_user
          #           credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
          #           buf << "Proxy-Authorization: Basic #{credential}\r\n"
          #         end
          buf << "\r\n"
          plain_sock.write(buf)
          HTTPResponse.read_new(plain_sock).value
          # assuming nothing left in buffers after successful CONNECT response

        end

        def send_request(request)
          socket = connect(request)
          # remove URI before sending request but cache it for restoring request
          uri_cache = request.remove_uri unless proxy?
          data = request.join

          unless request.has_body?
            data << "\r\n" unless data =~ /\r\n\r\n$/
          end

          socket.write data

          request.restore_uri(uri_cache) unless proxy?

          # request
          socket
        end

        def read_header(sock)
          h = []
          # puts '+ read header ...'
          # read first response line and add CRLF because .readline removed it
          begin
            h << sock.readline + "\r\n"
            while true
              line = sock.readuntil("\n", true) #.sub(/\s+\z/, '')
              h << line
              break if line.strip.empty?
            end
            return Watobo::Response.new(h)
          rescue => bang
            # TODO: Log
          end
          nil
        end

        def data_available?(sock, timeout = 1)
          read_sockets, _, _ = IO.select([sock.io], nil, nil, timeout)
          !read_sockets.nil? && !read_sockets.empty?
        end

        def read_all_nonblock(sock, timeout = 5)
          result = []

          loop do
            break unless data_available?(sock, timeout)

            begin
              data = sock.io.read_nonblock(4096)
              result << data
            rescue IO::WaitReadable
              # The socket is not readable, retry after a short delay
              sleep(0.1)
            rescue EOFError
              # The socket is closed, exit the loop
              break
            end
          end

          # binding.pry
          result.join
        end

        def read_body(sock, response)
          clen = response.content_length

          # binding.pry
          begin
            body = ''
            if response.is_chunked?
              body = read_chunked(sock)
              response.set_body body
              response.removeHeader("Transfer-Encoding")
              response.set_header("Content-Length", "#{body.length}")
              return response
              # TODO: check which kind of reading is best
              # Don't read by length, because if clen is larger than content
              # an error will be raised and no data is read
            elsif clen >= 0
              body = sock.read(clen) unless clen == 0
            else
              puts "!!!! start read_all !!!"
              # puts sock.class.to_s
              body = read_all_nonblock(sock)
              puts "!!!! FINISHED read_all !!!"
            end
            unless body.empty?
              response.set_body body
              response.set_header("Content-Length", "#{body.length}")
            end
          rescue EOFError
            # ignore
          rescue => e
            #binding.pry
            raise e
          end

          response
        end

        def connect(request)
          if proxy?
            conn_host = @proxy.host
            conn_port = @proxy.port
          else
            conn_host = request.host
            conn_port = request.port
          end

          conn_ip = IPSocket.getaddress(conn_host)

          s = Socket.tcp conn_ip, conn_port, nil, nil, connect_timeout: @open_timeout
          s.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

          if request.is_ssl?

            if proxy?
              plain_sock = ::Net::BufferedIO.new(s, read_timeout: @read_timeout,
                                                 write_timeout: @write_timeout,
                                                 continue_timeout: @continue_timeout,
                                                 debug_output: @debug_output)
              buf = "CONNECT #{request.host}:#{request.port} HTTP/#{1.1}\r\n"
              buf << "Host: #{request.host}:#{request.port}\r\n"
              # if proxy_user
              #  credential = ["#{proxy_user}:#{proxy_pass}"].pack('m0')
              #  buf << "Proxy-Authorization: Basic #{credential}\r\n"
              # end
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
            s.hostname = @sni_host ? @sni_host : request.host # if s.respond_to?(:hostname=) && ssl_host_address

            if @ssl_session and
              Process.clock_gettime(Process::CLOCK_REALTIME) < @ssl_session.time.to_f + @ssl_session.timeout
              s.session = @ssl_session
            end

            ssl_socket_connect(s, @open_timeout)

            if (@ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE) && verify_hostname
              s.post_connection_check(@address)
            end
            # debug "SSL established, protocol: #{s.ssl_version}, cipher: #{s.cipher[0]}"

            # call on_ssl_connect callback if present
            do_ssl_connect s
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
          # begin
          loop do
            line = sock.readline
            # next if line.strip.empty?
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

          # binding.pry
          # data << sock.read_all
          # rescue
          #
          # end
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
  # require 'net/http'

  prefs = { timeout: 10 }
  req = Watobo::Request.new ARGV[0]
  if ARGV.length > 1
    ARGV[1..-1].each do |arg|
      puts arg
      k, v = arg.split('=')
      next if v.nil?
      prefs[k.to_sym] = v
    end
  end
  puts "Request:"
  puts req.join
  # sender = Watobo::Net::Http::Sender.new req, prefs
  sender = Watobo::Net::Http::Sender.new prefs
  sender.on_header do |header|
    puts "\n\n[callback] on_header >>\nHeader loaded:"
    puts header.join
    puts '<<<'
  end

  sender.on_ssl_connect do |ssl|
    puts "\n\n[callback] on_ssl_connect"
    alt_names = []
    ssl.peer_cert.extensions.each do |e|
      ext = e.to_h
      alt_names << ext['value'] if ext['oid'] =~ /subjectaltname/i

    end
    puts alt_names
  end
  puts

  puts '+ send request ...'
  req, res = sender.exec req
  # puts res
  puts '-- META ---'
  puts res.meta.to_json

  puts res.content_type
  c = Nokogiri::HTML res.body.to_s
  puts c.css('title')
  # binding.pry

end