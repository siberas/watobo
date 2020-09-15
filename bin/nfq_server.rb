#!/usr/bin/ruby
require 'drb'
require 'yaml'
require 'json'
require 'openssl'

begin
  require "nfqueue"
  @nfq_present = true
rescue LoadError
  puts "NFQUEUE not available on this system"
  exit
end

# @private 
module Watobo#:nodoc: all
  module NFQ
    class Connections
      attr :nfqueue
      def add_ssl_request(c_host, c_port, s_host, s_port)
        ck = "#{c_host}:#{c_port}"
        sk = "#{s_host}:#{s_port}"

        begin

          unless @cert_list.has_key? sk
            if cert = acquire_cert(s_host,s_port)
            @connections[ck] = sk
            @cert_list[sk] = cert
            else
            return false
            end
          else
          @connections[ck] = sk
          end

          return true
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        return false

      end

      def to_yaml
        @connections.to_yaml
      end

      def info(data)
        begin
          ck = "#{data['host']}:#{data['port']}"
          target_site = ''
          cert_cn = ''
          @netqueue_lock.synchronize do
            if @connections.has_key? ck
              target_site = @connections[ck]
              if @cert_list.has_key? target_site
                cert = @cert_list[target_site]
                cert_cn = cert.subject.to_s.gsub(/.*=/,"")
              end
            end
          end
          r = { 'target' => target_site, 'cn' => cert_cn}
          return r
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        return {}
      end

      def initialize(config=nil)
        @connections = Hash.new
        @cert_list = Hash.new
        @netqueue_lock = Mutex.new
        @dh_key = OpenSSL::PKey::DH.new(512)
        @nfqueue = start
        @cfg = nil
        @client_certs={}
        unless config.nil?
          @cfg = JSON.parse(File.read(config))

          if @cfg['cert_file'] =~/\.p12$/

            file = File.join(File.dirname(config), @cfg['cert_file'])
            puts "+ load PKCS12 certificate from file #{file}"
            p12 = OpenSSL::PKCS12.new( File.read(file), @cfg['password'])
            @client_certs[@cfg['ip_addr']] = {
                cert: p12.certificate,
                key: p12.key
            }


          end

        end
      end

      def acquire_cert(host, port)

        begin
          tcp_socket = TCPSocket.new( host, port )
          tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          tcp_socket.sync = true
          ctx = OpenSSL::SSL::SSLContext.new()

          ctx.tmp_dh_callback = proc { |*args|
            @dh_key
          }

          if !!@client_certs[host]
            puts "+ got client cert for host #{host}"
            ctx.cert = @client_certs[host][:cert]
            ctx.key = @client_certs[host][:key]
          end

          socket = OpenSSL::SSL::SSLSocket.new(tcp_socket, ctx)

          socket.connect
          #socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
          sk = "#{host}:#{port}"
          cert = socket.peer_cert
          @netqueue_lock.synchronize do
            @cert_list[sk] = cert
          end
          # puts cert.subject.methods.sort
          return cert

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def start

        puts "starting netfilter_queue ..."
        t = Thread.new{
          begin
            Netfilter::Queue.create(0) do |p|
            #   puts ">> Netfilter Packet #" + p.id.to_s
            #  $stdout.flush
            #   puts p.data.class
              raw_src = p.data[12..15]
              raw_dst = p.data[16..19]
              src_port = p.data[20..21].unpack("H4")[0].hex
              dst_port = p.data[22..24].unpack("H4")[0].hex
              # if p.data.length > 47
              # flags = p.data[47].unpack("H*")[0].hex
              # puts flags.to_s
              # if flags == 2
              #    puts  "ADD SSL REQUEST"
              puts "NFQ >> #{get_ip_string(raw_src)}:#{src_port} -> #{get_ip_string(raw_dst)}:#{dst_port}"
              add_ssl_request(get_ip_string(raw_src), src_port, get_ip_string(raw_dst), dst_port)

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

        t
      end

      private

      def get_ip_string(raw_addr)
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

    end

  end
end

@config = ARGV[0]

DRb.start_service "druby://127.0.0.1:9090", Watobo::NFQ::Connections.new( @config)
#puts DRb.uri
DRb.thread.join

