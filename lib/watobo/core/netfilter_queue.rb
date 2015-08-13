# @private 
module Watobo#:nodoc: all
  module NFQueue
    @ssl_requests = Hash.new
    @cert_list = Hash.new

    @netqueue_lock = Mutex.new
    @t_nfqueue = nil

    @nfq_present = false

    begin
      require "nfqueue"
      @nfq_present = true
    rescue LoadError
      puts "NFQUEUE not available on this system"
    end

    def self.get_ip_string(raw_addr)
      begin
        ip = ""
        raw_addr.length.times do |i|
          ip << "." unless ip.empty?
          ip << raw_addr[i].ord.to_s
        end
      rescue => bang
        puts bang
        puts bang.backtrace
      end
      ip
    end

    def self.stop
      @t_nfqueue.kill if @t_nfqueue.respond_to? :kill
    end

    def self.start
      #  @t_nfqueue.raise unless @t_nfqueue.nil?
      puts @t_nfqueue.status if @t_nfqueue.respond_to? :status

      puts "starting netfilter_queue ..."
      @t_nfqueue = Thread.new{
       begin
        Netfilter::Queue.create(0) do |p|
          puts ">> Netfilter Packet #" + p.id.to_s
        #  $stdout.flush
          puts p.data.class
          raw_src = p.data[12..15]
          raw_dst = p.data[16..19]
          src_port = p.data[20..21].unpack("H4")[0].hex
          dst_port = p.data[22..24].unpack("H4")[0].hex
         # if p.data.length > 47
         # flags = p.data[47].unpack("H*")[0].hex
         # puts flags.to_s
         # if flags == 2
          puts  "ADD SSL REQUEST"
          puts "#{get_ip_string(raw_src)}:#{src_port} -> #{get_ip_string(raw_dst)}:#{dst_port}"
           @netqueue_lock.synchronize do
          if add_ssl_request(get_ip_string(raw_src), src_port, get_ip_string(raw_dst), dst_port)
          puts "OK"
          end
          end
          #end
          #end
          Netfilter::Packet::ACCEPT
        end
      rescue => bang
       puts bang
       puts bang.backtrace
      # retry
      rescue Netfilter::QueueError
      puts "NetfilterERROR"
      exit
      end
      }

      @t_nfqueue
    end

    def self.add_ssl_request(c_host, c_port, s_host, s_port)
      ck = "#{c_host}:#{c_port}"
      sk = "#{s_host}:#{s_port}"

      begin

        unless @cert_list.has_key? sk
          if cert = acquire_cert(s_host,s_port)
          @ssl_requests[ck] = sk
          @cert_list[sk] = cert
          else
          return false
          end
        else
        @ssl_requests[ck] = sk
        end

        return true
      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return false

    end

    def self.get_connection_info(c_host,c_port)
      begin
        ck = "#{c_host}:#{c_port}"
        target_site = nil
        cert = nil
        @netqueue_lock.synchronize do
          if @ssl_requests.has_key? ck
          target_site = @ssl_requests[ck]
          cert = @cert_list[target_site] if @cert_list.has_key? target_site
          end
        end
        return target_site, cert
      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return nil, nil
    end

    def self.acquire_cert(host, port)
      puts "* acquire cert ... #{host}:#{port}"
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
        #socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        sk = "#{host}:#{port}"
        cert = socket.peer_cert
        @cert_list[sk] = cert
        puts "PEER CERT SUBJECT: #{cert.subject}"
        # puts cert.subject.methods.sort
        return cert

      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return nil
    end

  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..","..","..", "lib")) # this is the same as rubygems would do
  $: << inc_path

  require 'watobo'
  require 'nfqueue'

  Watobo::Interceptor.proxy_mode = Watobo::Interceptor::MODE_TRANSPARENT
  @iproxy = Watobo::InterceptProxy.new()
  @iproxy.run
  while 1
    sleep 1
  end
end
