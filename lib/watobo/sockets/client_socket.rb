# @private
module Watobo #:nodoc: all
  module HTTPSocket
    class ClientSocket
      attr_accessor :port
      attr_accessor :address
      attr_accessor :host
      attr_accessor :site
      attr_accessor :ssl

      def write(data)
        @socket.write data
        @socket.flush
      end

      def flush
        @socket.flush
      end

      def close
        begin
          #if socket.class.to_s =~ /SSLSocket/
          if @socket.respond_to? :shutdown
            @socket.shutdown(Socket::SHUT_RDWR)
          end
          # finally close it
          if @socket.respond_to? :close
            @socket.close
          elsif @socket.respond_to? :sysclose
            socket.io.shutdown(Socket::SHUT_RDWR)
            @socket.sysclose
          end
          return true
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        false
      end

      def read_header
        request = []
        Watobo::HTTPSocket.read_client_header(@socket) do |line|
          request << line
        end

        return nil if request.empty?
        unless request.first =~ /(^[^[:space:]]{1,}) http/
          request.first.gsub!(/(^[^[:space:]]{1,})( )(\/.*)/, "\\1 https://#{@site}\\3")
        end

        Watobo::Request.new(request)
      end

      def ssl?
        @ssl == true
      end

      def request
        @persistent = false
        begin
          unless @initial_request.nil?
            request = @initial_request.copy

            #puts "\n>> Request RAW:"
            #puts request
            #puts "\n>> Request RAW (HEX):"
            #puts request.join.unpack("H*")[0]

            @initial_request = nil
            clean_request request
            return request
          end

          request = read_header

          return nil if request.nil?

          @persistent = !request.connection_close?

          clen = request.content_length
          if clen > 0 then
            body = ""
            Watobo::HTTPSocket.read_body(@socket) do |data|
              body << data
              break if body.length == clen
            end

            #puts "* CLEN = #{clen} - read body (#{body.length})"
            request << body
          end
        rescue => bang
          puts bang
        end

        #puts "\n>> Request RAW:"
        #puts request
        #puts "\n>> Request RAW (HEX):"
        #  puts request.unpack("H*")[0]

        clean_request request

        request
      end

      def send_response(response)

      end

      def initialize(socket, req=nil)
        @socket = socket
        @port = nil
        @address = nil
        @host = nil
        @site = nil
        @ssl = false
        @initial_request = req
        @persistent = false

        # TODO: Fake Certs Should be global accessable

      end

      def self.connect(socket)
        request = []
        @fake_certs ||= {}
        @dh_key ||= Watobo::CA.dh_key

        ra = socket.remote_address
        cport = ra.ip_port
        caddr = ra.ip_address
        #puts cport
        #puts caddr

        optval = [1, 500_000].pack("I_2")
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1
        socket.sync = true

        session = socket

        if Watobo::Interceptor::Proxy.transparent?


          ci = Watobo::Interceptor::Transparent.info({'host' => caddr, 'port' => cport})
          unless ci.nil? or ci['target'].empty? or ci['cn'].empty?
            #puts "SSL-REQUEST FROM #{caddr}:#{cport}"

            ctx = Watobo::CertStore.acquire_ssl_ctx ci['target'], ci['cn']

            begin
              ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
              #ssl_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
              # ssl_socket.sync_close = true
              ssl_socket.sync = true
              # puts ssl_socket.methods.sort
              session = ssl_socket.accept
            rescue OpenSSL::SSL::SSLError => e
              puts ">> SSLError"
              puts e
              #puts session.methods.sort
              return nil, session
            rescue => bang
              puts bang
              puts bang.backtrace
              return nil, session
            end
          end
        end

        begin
          Watobo::HTTPSocket.read_header(session) do |line|
            request << line
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          return nil
        end

        return nil if request.empty?

        if Watobo::Interceptor::Proxy.transparent?
          #puts "> get hostname ..."
          thn = nil
          request.each do |l|
            if l =~ /^Host: (.*)/
              thn = $1.strip
              #   puts ">> #{thn}"
            end
          end
          # puts session.class
          # puts "* fix request line ..."
          # puts request.first
          # puts ">>"
          if session.is_a? OpenSSL::SSL::SSLSocket
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i, "\\1 https://#{thn}\\2 \\3") unless request.first =~ /^[^[:space:]]{1,} http/
          else
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i, "\\1 http://#{thn}\\2 \\3") unless request.first =~ /^[^[:space:]]{1,} http/
          end
          #puts request.first
        end

        if request.first =~ /^CONNECT (.*):(\d{1,5}) HTTP\/1\./ then
          target = $1
          tport = $2
          # puts request.first
          # print "\n* CONNECT: #{target} on port #{tport}\n"
          site = "#{target}:#{tport}"
          #puts "CONNECT #{site}"

          begin
            socket.print "HTTP/1.0 200 Connection established\r\n" +
                             #"Proxy-connection: Keep-alive\r\n" +
                             "Proxy-agent: WATOBO-Proxy/1.1\r\n" +
                             "\r\n"
            bscount = 0 # bad handshake counter
            #  puts "* wait for ssl handshake ..."

            unless @fake_certs.has_key? site
              puts "CREATE NEW CERTIFICATE FOR >> #{site} <<"
              cn = Watobo::HTTPSocket.get_ssl_cert_cn(target, tport)
              puts "CN=#{cn}"

              cert = {
                  :hostname => cn,
                  :type => 'server',
                  :user => 'watobo',
                  :email => 'root@localhost',
              }

              cert_file, key_file = Watobo::CA.create_cert cert
              @fake_certs[site] = {
                  :cert => OpenSSL::X509::Certificate.new(File.read(cert_file)),
                  :key => OpenSSL::PKey::RSA.new(File.read(key_file))
              }
            end
            ctx = OpenSSL::SSL::SSLContext.new()

            #ctx.cert = @cert
            ctx.cert = @fake_certs[site][:cert]
            #  @ctx.key = OpenSSL::PKey::DSA.new(File.read(key_file))
            #ctx.key = @key
            ctx.key = @fake_certs[site][:key]
            ctx.tmp_dh_callback = proc {|*args|
              @dh_key
            }

           # if ctx.respond_to? :tmp_ecdh_callback
           #   ctx.tmp_ecdh_callback = ->(*args) {
           #     called = true
           #     OpenSSL::PKey::EC.new 'prime256v1'
           #   }
           # end

            ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
            ctx.timeout = 10

            ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
            ssl_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
            #  ssl_socket.sync_close = true
            ssl_socket.sync = true
            # puts ssl_socket.methods.sort

            ssl_session = ssl_socket.accept

            session = ssl_session
            request = []

            Watobo::HTTPSocket.read_header(session) do |line|
              request << line
            end
            return nil if request.empty?
            return nil if request.first.nil?

            unless request.first =~ /(^[^[:space:]]{1,}) http/
              request.first.gsub!(/(^[^[:space:]]{1,})( )(\/.*)/, "\\1 https://#{site}\\3")
            end

            request = Watobo::Request.new(request)
          rescue => bang
            puts '! could not answer request for site ' + site
            puts bang if $VERBOSE
            if $DEBUG
              puts bang.backtrace
            end

            return nil

          end

        else
          # puts "* create request object"
          request = Watobo::Request.new(request)
          site = request.site
          #puts request
        end

        #puts "CLIENT REQUEST:"
        #puts request

        begin

          unless request.nil?
            clen = request.content_length
            if clen > 0 then
              body = ""
              Watobo::HTTPSocket.read_body(session) do |data|
                body << data
                break if body.length == clen
              end

              request << body unless body.empty?
            end
            connection = ClientSocket.new(session, request)
          else
            connection = ClientSocket.new(session)
          end

          connection.ssl = true if session.class.to_s =~ /ssl/i

          # ra = session.remote_address
          # connection.port = ra.ip_port
          # connection.address = ra.ip_address
          # connection.site = site

          connection.port = cport
          connection.address = caddr
          connection.site = site
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        connection
      end

      private

      # clean request removes unneccessary headers
      # e.g., hop_by_hop headers
      def clean_request(request)
        # puts request
        request.remove_header "^Connection"
        request.remove_header "^Proxy\-Connection"
        request.remove_header "^If\-"
        request.remove_header "^Expect.*continue"

        request.unzip!

        #  request.remove_header("^Accept-Encoding")
      end

    end

    class ClientSocket_ORIG
      attr_accessor :port
      attr_accessor :address
      attr_accessor :host
      attr_accessor :site
      attr_accessor :ssl

      def write(data)
        @socket.write data
        @socket.flush
      end

      def flush
        @socket.flush
      end

      def close
        begin
          #if socket.class.to_s =~ /SSLSocket/
          if @socket.respond_to? :shutdown
            @socket.shutdown(Socket::SHUT_RDWR)
          end
          # finally close it
          if @socket.respond_to? :close
            @socket.close
          elsif @socket.respond_to? :sysclose
            socket.io.shutdown(Socket::SHUT_RDWR)
            @socket.sysclose
          end
          return true
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        false
      end

      def read_header
        request = []
        Watobo::HTTPSocket.read_client_header(@socket) do |line|
          request << line
        end

        return nil if request.empty?
        unless request.first =~ /(^[^[:space:]]{1,}) http/
          request.first.gsub!(/(^[^[:space:]]{1,})( )(\/.*)/, "\\1 https://#{@site}\\3")
        end

        Watobo::Request.new(request)
      end

      def ssl?
        @ssl == true
      end

      def request
        begin
          unless @initial_request.nil?
            request = @initial_request.copy
            @initial_request = nil
            return request
          end

          request = read_header

          return nil if request.nil?

          clen = request.content_length
          if clen > 0 then
            body = ""
            Watobo::HTTPSocket.read_body(@socket) do |data|
              body += data
              break if body.length == clen
            end
            request << body
          end
        rescue => bang
          puts bang
        end

        puts request

        request
      end

      def initialize(socket, req=nil)
        @socket = socket
        @port = nil
        @address = nil
        @host = nil
        @site = nil
        @ssl = false
        @initial_request = req

        # TODO: Fake Certs Should be global accessable

      end

      def self.connect(socket)
        request = []
        @fake_certs ||= {}
        @dh_key ||= Watobo::CA.dh_key

        ra = socket.remote_address
        cport = ra.ip_port
        caddr = ra.ip_address

        optval = [1, 500_000].pack("I_2")
        #socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        #socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        #socket.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1
        socket.sync = true

        session = socket

        if Watobo::Interceptor::Proxy.transparent?

          ci = Watobo::Interceptor::Transparent.info({'host' => caddr, 'port' => cport})
          unless ci['target'].empty? or ci['cn'].empty?
            puts "SSL-REQUEST FROM #{caddr}:#{cport}"

            ctx = Watobo::CertStore.acquire_ssl_ctx ci['target'], ci['cn']

            begin
              ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
              #ssl_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
              # ssl_socket.sync_close = true
              ssl_socket.sync = true
              # puts ssl_socket.methods.sort
              session = ssl_socket.accept
            rescue OpenSSL::SSL::SSLError => e
              puts ">> SSLError"
              puts e
              return nil, session
            rescue => bang
              puts bang
              puts bang.backtrace
              return nil, session
            end
          else
            puts ci['host']
            puts ci['cn']
          end
        end

        begin
          Watobo::HTTPSocket.read_header(session) do |line|
            request << line
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          return nil
        end

        if Watobo::Interceptor::Proxy.transparent?
          #puts "> get hostname ..."
          thn = nil
          request.each do |l|
            if l =~ /^Host: (.*)/
              thn = $1.strip
              #   puts ">> #{thn}"
            end
          end
          # puts session.class
          # puts "* fix request line ..."
          # puts request.first
          # puts ">>"
          if session.is_a? OpenSSL::SSL::SSLSocket
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i, "\\1 https://#{thn}\\2 \\3") unless request.first =~ /^[^[:space:]]{1,} http/
          else
            request.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i, "\\1 http://#{thn}\\2 \\3") unless request.first =~ /^[^[:space:]]{1,} http/
          end
          #puts request.first
        end

        if request.first =~ /^CONNECT (.*):(\d{1,5}) HTTP\/1\./ then
          target = $1
          tport = $2
          # puts request.first
          #print "\n* CONNECT: #{method} #{target} on port #{tport}\n"
          site = "#{target}:#{tport}"
          #puts "CONNECT #{site}"

          socket.print "HTTP/1.0 200 Connection established\r\n" +
                           #"Proxy-connection: Keep-alive\r\n" +
                           "Proxy-agent: WATOBO-Proxy/1.1\r\n" +
                           "\r\n"
          bscount = 0 # bad handshake counter
          #  puts "* wait for ssl handshake ..."
          begin
            # site = "#{target}:#{tport}"
            unless @fake_certs.has_key? site
              puts "CREATE NEW CERTIFICATE FOR >> #{site} <<"
              cn = Watobo::HTTPSocket.get_ssl_cert_cn(target, tport)
              puts "CN=#{cn}"

              cert = {
                  :hostname => cn,
                  :type => 'server',
                  :user => 'watobo',
                  :email => 'root@localhost',
              }

              cert_file, key_file = Watobo::CA.create_cert cert
              @fake_certs[site] = {
                  :cert => OpenSSL::X509::Certificate.new(File.read(cert_file)),
                  :key => OpenSSL::PKey::RSA.new(File.read(key_file))
              }
            end
            ctx = OpenSSL::SSL::SSLContext.new()

            #ctx.cert = @cert
            ctx.cert = @fake_certs[site][:cert]
            #  @ctx.key = OpenSSL::PKey::DSA.new(File.read(key_file))
            #ctx.key = @key
            ctx.key = @fake_certs[site][:key]
            ctx.tmp_dh_callback = proc {|*args|
              @dh_key
            }

            ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
            ctx.timeout = 10

            ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ctx)
            ssl_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
            #  ssl_socket.sync_close = true
            ssl_socket.sync = true
            # puts ssl_socket.methods.sort

            ssl_session = ssl_socket.accept
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG

            return nil

          end
          session = ssl_session
          request = nil
        else
          # puts "* create request object"
          request = Watobo::Request.new(request)
          site = request.site
          #puts request
        end

        begin

          unless request.nil?
            clen = request.content_length
            if clen > 0 then
              body = ""
              Watobo::HTTPSocket.read_body(session) do |data|
                body += data
                break if body.length == clen
              end
              request << body unless body.empty?
            end
            connection = ClientSocket.new(session, request)
          else
            connection = ClientSocket.new(session)
          end

          connection.ssl = true if session.class.to_s =~ /ssl/i

          # ra = session.remote_address
          # connection.port = ra.ip_port
          # connection.address = ra.ip_address
          # connection.site = site

          connection.port = cport
          connection.address = caddr
          connection.site = site
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        connection
      end

    end

  end
end
