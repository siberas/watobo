# @private
module Watobo#:nodoc: all
  module HTTPSocket
    def self.close(socket)
      #  def close
      begin
      #if socket.class.to_s =~ /SSLSocket/
        if socket.respond_to? :sysclose
        #socket.io.shutdown(2)
        socket.sysclose
        elsif socket.respond_to? :shutdown
          #puts "SHUTDOWN"
          socket.shutdown(Socket::SHUT_RDWR)
        end
        # finally close it
        if socket.respond_to? :close
        socket.close
        end
        return true
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      false
    # end
    end

    def self.siteAlive?(chat)
      #puts chat.class
      site = nil
      host = nil
      port = nil

      site = chat.request.site

      #return @sites_online[site] if @sites_online.has_key?(site)

      proxy = Watobo::ForwardingProxy.get site

      unless proxy.nil?
        Watobo.print_debug("Using Proxy","#{proxy.to_yaml}") if $DEBUG

        puts "* testing proxy connection:"
        puts "#{proxy.name} (#{proxy.host}:#{proxy.port})"

      host = proxy.host
      port = proxy.port

      else
        print "* check if site is alive (#{site}) ... "
      host = chat.request.host
      port = chat.request.port

      end

      return false if host.nil? or port.nil?

      begin
        tcp_socket = nil
        #  timeout(6) do

        tcp_socket = TCPSocket.new( host, port)
        tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.sync = true

        socket = tcp_socket

        if socket.class.to_s =~ /SSLSocket/
        socket.io.shutdown(2)
        else
        socket.shutdown(2)
        end
        socket.close
        print "[OK]\n"

        return true
      rescue Errno::ECONNREFUSED
        p "* connection refused (#{host}:#{port})"
      rescue Errno::ECONNRESET
        puts "* connection reset"
      rescue Errno::EHOSTUNREACH
        p "* host unreachable (#{host}:#{port})"

      rescue Timeout::Error
        p "* TimeOut (#{host}:#{port})\n"

      rescue Errno::ETIMEDOUT
        p "* TimeOut (#{host}:#{port})"

      rescue Errno::ENOTCONN
        puts "!!!ENOTCONN"
      rescue OpenSSL::SSL::SSLError
        p "* ssl error"
        socket = nil
        #  puts "!!! SSL-Error"
        print "E"
      rescue => bang
      #  puts host
      #  puts port
        puts bang
        puts bang.backtrace if $DEBUG
      end
      print "[FALSE]\n"

      return false
    end

    def self.get_ssl_cert_cn( host, port)
      cn = ""
      begin
        tcp_socket = TCPSocket.new( host, port )
        tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.sync = true
        ctx = OpenSSL::SSL::SSLContext.new()

        ctx.tmp_dh_callback = proc { |*args|
          OpenSSL::PKey::DH.new(128)
        }

        socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)

        socket.connect
        cert = socket.peer_cert

        if cert.subject.to_s =~ /cn=([^\/]*)/i
        cn = $1
        end
        puts "Peer-Cert CN: #{cn}"
        socket.io.shutdown(2)
      rescue => bang
        puts bang
        cn = host
      ensure
        socket.close if socket.respond_to? :close
      end
      cn
    end

    def self.get_peer_subject(socket)
      begin
        ctx = OpenSSL::SSL::SSLContext.new()
        ctx.tmp_dh_callback = proc { |*args|
          OpenSSL::PKey::DH.new(128)
        }
        ssl_sock = OpenSSL::SSL::SSLSocket.new(socket, ctx)
        subject = ssl_sock.peer_cert.subject
        return subject
      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return nil
    end

    def self.read_body(socket, prefs=nil)
      buf = nil
      max_bytes = -1
      unless prefs.nil?
        max_bytes = prefs[:max_bytes] unless prefs[:max_bytes].nil?
      end
      bytes_to_read = max_bytes >= 0 ? max_bytes : 1024

      bytes_read = 0
      while max_bytes < 0 or bytes_to_read > 0
        begin
        #   timeout(5) do
        # puts "<#{bytes_to_read} / #{bytes_read} / #{max_bytes}"
          buf = socket.readpartial(bytes_to_read)
          bytes_read += buf.length
          #   end
        rescue EOFError
          if $DEBUG
            puts "#{buf.class} - #{buf}"
          end
          # unless buf.nil?
          #   yield buf if block_given?
          # end
          #buf = nil
          break
          #return
        rescue Timeout::Error
          puts "!!! Timeout: read_body (max_bytes=#{max_bytes})"
          #puts "* last data seen on socket:"
          # puts buf
          puts $!.backtrace if $DEBUG
          break
        rescue => bang
          print "E!"
          puts bang.backtrace if $DEBUG
        break
        end
        break if buf.nil?
        yield buf if block_given?
        break if max_bytes >= 0 and bytes_read >= max_bytes
        bytes_to_read -= bytes_read if max_bytes >= 0 && bytes_to_read >= bytes_read
      end
      return
    end

    def self.readChunkedBody(socket, &block)
      buf = nil
      while (chunk_size = socket.gets)
        
        if chunk_size.strip.empty?
          yield chunk_size
          next 
        end
        next unless chunk_size.strip =~/^[a-fA-F0-9]+$/
        yield "#{chunk_size.strip}\n" if block_given?
        bytes_to_read = num_bytes = chunk_size.strip.hex
        # puts "> chunk-length: 0x#{chunk_size.strip}(#{num_bytes})"
        return if num_bytes == 0
        bytes_read = 0
        while bytes_read < num_bytes
          begin
          # timeout(5) do
            bytes_to_read = num_bytes - bytes_read
            # puts bytes_to_read.to_s
            buf = socket.readpartial(bytes_to_read)
            bytes_read += buf.length
            # puts bytes_read.to_s
            # end
          rescue EOFError
          # yield buf if buf
            return
          rescue Timeout::Error
            puts "!!! Timeout: readChunkedBody (bytes_to_read=#{bytes_to_read}"
            #puts "* last data seen on socket:"
            # puts buf
            return
          rescue => bang
          # puts "!!! Error (???) reading body:"
          # puts bang
          # puts bang.class
          # puts bang.backtrace.join("\n")
          # puts "* last data seen on socket:"
          # puts buf
            print "E!"
          return
          end
          # puts bytes_read.to_s
          yield buf if block_given?
        #return if max_bytes > 0 and bytes_read >= max_bytes
        end
        yield "\r\n" if block_given?
      end
    #  end
    end

    def self.read_header(socket)
      buf = ''

      while true
        begin
          buf = socket.gets
        rescue EOFError
          puts "!!! EOF: reading header"
          # buf = nil
          return
        rescue Errno::ECONNRESET
        #puts "!!! CONNECTION RESET: reading header"
        #buf = nil
        #return
          raise
        rescue Errno::ECONNABORTED
          raise
        rescue Timeout::Error
        #puts "!!! TIMEOUT: reading header"
        #return
          raise
        rescue => bang
        # puts "!!! READING HEADER:"
        # puts buf
          puts bang
          puts bang.backtrace
          raise
        end

        return if buf.nil?

        yield buf if block_given?
        return if buf.strip.empty?
      end
    end

    def self.read_client_header(socket)
      buf = ''

      while true
        begin
        #Timeout::timeout(1.5) do
          buf = socket.gets
          #end
        rescue EOFError => e
          puts "EOFError: #{e}"
          #puts "!!! EOF: reading header"
          # buf = nil
          return true
        rescue Errno::ECONNRESET => e
          puts "ECONNRESET: #{e}"
          #puts "!!! CONNECTION RESET: reading header"
          #buf = nil
          #return
          #raise
          return false
        rescue Errno::ECONNABORTED => e
          puts "ECONNABORTED: #{e}"
          #raise
          return false
        rescue Timeout::Error => e
          puts "TIMEOUT: #{e}"
          return false
        rescue => bang
        # puts "!!! READING HEADER:"
        # puts buf
          puts bang
          puts bang.backtrace
          raise
        end

        return false if buf.nil?
        
       # puts buf

        yield buf if block_given?
        return if buf.strip.empty?
      end
    end

  end
end

