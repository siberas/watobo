# @private 
module Watobo#:nodoc: all
  module CertStore
    @fake_certs = Hash.new
    def self.acquire_ssl_ctx(target, cn)
      ctx = OpenSSL::SSL::SSLContext.new()

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

      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      ctx.timeout = 10
      return ctx
    end
  end
end