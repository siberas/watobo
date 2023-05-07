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

            puts "* CLEN = #{clen} - read body (#{body.length})"
            request << body
          end
          clean_request request

          return request
        rescue => bang
          puts bang
          if $DEBUG
            puts bang.backtrace
            puts "\n>> Request RAW:"
            puts request
            puts "\n>> Request RAW (HEX):"
            puts request.unpack("H*")[0]
          end
        end

        return nil
      end

      def send_response(response)

      end

      def initialize(socket, req = nil)
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
        if $DEBUG
          puts cport
          puts caddr
        end

        optval = [1, 500_000].pack("I_2")
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, optval
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, optval
        socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
        # socket.setsockopt Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1
        socket.sync = true

        session = socket

        if Watobo::Interceptor::Proxy.transparent?

          puts "* running transparent ..." if $VERBOSE

          ci = Watobo::Interceptor::Transparent.info({'host' => caddr, 'port' => cport})
          unless ci.nil? or ci['target'].empty? or ci['cn'].empty?
            puts "SSL-REQUEST FROM #{caddr}:#{cport}" if $VERBOSE

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
              puts e.backtrace if $DEBUG
              #puts session.methods.sort
              return nil, session
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
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

              # no longer use get_ssl_cert_cn because cn does not necessarily match the requested hostname
              # example: maps.googleapis.com
              # [6] pry(Watobo::HTTPSocket)> cert.extensions.map{|e| e.to_s }
              # => ["keyUsage = critical, Digital Signature",
              #  "extendedKeyUsage = TLS Web Server Authentication",
              #  "basicConstraints = critical, CA:FALSE",
              #  "subjectKeyIdentifier = 67:D9:92:3D:DC:37:0C:67:24:94:9C:D7:3E:E4:7E:C3:E3:FA:E1:59",
              #  "authorityKeyIdentifier = keyid:98:D1:F8:6E:10:EB:CF:9B:EC:60:9F:18:90:1B:A0:EB:7D:09:FD:2B, ",
              #  "authorityInfoAccess = OCSP - URI:http://ocsp.pki.goog/gts1o1core, CA Issuers - URI:http://pki.goog/gsr2/GTS1O1.crt, ",
              #  "subjectAltName = DNS:upload.video.google.com, DNS:*.clients.google.com, DNS:*.docs.google.com, DNS:*.drive.google.com, DNS:*.gdata.youtube.com, DNS:*.googleapis.com, DNS:*.photos.google.com, DNS:*.upload.google.com, DNS:*.upload.youtube.com, DNS:*.youtube-3rd-party.com, DNS:bg-call-donation-alpha.goog, DNS:bg-call-donation-canary.goog, DNS:bg-call-donation-dev.goog, DNS:bg-call-donation.goog, DNS:upload.google.com, DNS:upload.youtube.com, DNS:uploads.stage.gdata.youtube.com",
              #  "certificatePolicies = Policy: 2.23.140.1.2.2, Policy: 1.3.6.1.4.1.11129.2.5.3, ",
              #  "crlDistributionPoints = , Full Name:,   URI:http://crl.pki.goog/GTS1O1core.crl, ",
              #  "ct_precert_scts = Signed Certificate Timestamp:,     Version   : v1 (0x0),     Log ID    : 5C:DC:43:92:FE:E6:AB:45:44:B1:5E:9A:D4:56:E6:10:,                 37:FB:D5:FA:47:DC:A1:73:94:B2:5E:E6:F6:C7:0E:CA,     Timestamp : Mar 11 15:58:59.728 2021 GMT,     Extensions: none,     Signature : ecdsa-with-SHA256,                 30:45:02:21:00:D2:A5:41:D8:6D:1E:2D:54:78:A6:8F:,                 27:CE:74:FA:2D:89:2B:A1:F8:45:A5:91:72:73:9C:AD:,                 7A:A2:F7:E7:2B:02:20:6E:85:0A:86:E7:C2:71:98:D4:,                 9D:17:C8:60:DD:AC:88:71:3F:29:F4:78:15:A8:E4:1C:,                 17:C8:35:01:3D:F5:B1, Signed Certificate Timestamp:,     Version   : v1 (0x0),     Log ID    : 7D:3E:F2:F8:8F:FF:88:55:68:24:C2:C0:CA:9E:52:89:,                 79:2B:C5:0E:78:09:7F:2E:6A:97:68:99:7E:22:F0:D7,     Timestamp : Mar 11 15:58:59.521 2021 GMT,     Extensions: none,     Signature : ecdsa-with-SHA256,                 30:45:02:21:00:C5:52:70:30:49:7F:C9:D0:E7:45:B7:,                 7C:08:54:40:30:0C:ED:91:40:E4:71:C9:3E:9A:FA:31:,                 BC:90:3B:C7:4B:02:20:7D:E8:48:79:84:7E:44:C4:69:,                 42:CE:4D:CC:A5:59:37:03:3B:BA:C6:A1:B4:E5:44:12:,                 B6:DF:7D:02:8B:B3:C8"]
              # cn = Watobo::HTTPSocket.get_ssl_cert_cn(target, tport)
              cn = target
              puts "CN=#{cn}"

              cert = {
                  :hostname => cn,
                  :type => 'server',
                  :user => 'watobo',
                  :email => 'root@localhost',
              }

              cert_file, key_file = Watobo::CA.create_cert cert

              full_chain = File.read Watobo::CA.cert_file
              server_cert = File.read(cert_file)
              @fake_certs[site] = {
                  #:cert => OpenSSL::X509::Certificate.new(File.read(cert_file)),
                  :cert => OpenSSL::X509::Certificate.new(server_cert),
                  :extra_chain_cert => [OpenSSL::X509::Certificate.new(full_chain)],
                  :key => OpenSSL::PKey::RSA.new(File.read(key_file))
              }
            end
            ctx = OpenSSL::SSL::SSLContext.new()

            #ctx.cert = @cert
            ctx.cert = @fake_certs[site][:cert]
            #  @ctx.key = OpenSSL::PKey::DSA.new(File.read(key_file))
            #ctx.key = @key
            ctx.key = @fake_certs[site][:key]
            ctx.extra_chain_cert = @fake_certs[site][:extra_chain_cert]

            ctx.tmp_dh_callback = proc { |*args|
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


  end
end
