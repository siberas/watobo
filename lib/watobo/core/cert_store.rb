# @private 
module Watobo#:nodoc: all
  module CertStore
    @fake_certs = Hash.new
    def self.acquire_ssl_ctx(target, cn)
      #OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers] = 'TLSv1.2:!aNULL:!eNULL'
      ctx = OpenSSL::SSL::SSLContext.new()
      #ctx = OpenSSL::SSL::SSLContext.new(:TLSv1_2_server)
      #ctx.ssl_version = :TLSv1_2_server
      #ctx.ciphers='TLSv1.2:!aNULL:!eNull'

      unless @fake_certs.has_key? target
        cert_prefs = {
          :hostname => cn,
          :type => 'server',
          :user => 'watobo',
          :email => 'watobo@localhost',
        }
        cert_file, key_file = Watobo::CA.create_cert cert_prefs
        fake_cert = OpenSSL::X509::Certificate.new(File.read(cert_file))
        fake_key = OpenSSL::PKey::RSA.new(File.read(key_file))

        #ctx = OpenSSL::SSL::SSLContext.new('SSLv23_server')
        @fake_certs[target] = { :cert => fake_cert, :key => fake_key }

      end
      fc = @fake_certs[target]
      ctx.cert = fc[:cert]
      ctx.key = fc[:key]

      ctx.tmp_dh_callback = proc { |*args|
        Watobo::CA.dh_key
      }

      if ctx.respond_to? :tmp_ecdh_callback
        ctx.tmp_ecdh_callback = ->(*args){
          called = true
          OpenSSL::PKey::EC.new 'prime256v1'
        }
      end


      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx.timeout = 10
      ctx.ciphers.each do |c|
        puts c[0] + ' : ' + c[1] + ' : ' +c[2].to_s
      end
      return ctx
    end
  end
end