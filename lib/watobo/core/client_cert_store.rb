# @private 
module Watobo#:nodoc: all
  module ClientCertStore#:nodoc: all
    @client_certs = {}
    @project = nil

    #    :ssl_client_cert
    #    :ssl_client_key
    #    :extra_chain_certs
    #    :password
    #    :save_pw [Bool]
    #    :insert [Bool]

    def self.clear
      @client_certs.clear
    end

    def self.add_pem( site, cert_file, key_file, password=nil)
      cinfo = { :type => :pem,
                :certificate_file => cert_file,
                :key_file => key_file,
                :password => password
      }
      begin
        cinfo[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(cert_file))
        cinfo[:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(key_file), cinfo[:password])
        @client_certs[site] = cinfo
        return false
      rescue => bang
        puts bang
      end
      false

    end

    def self.add_pkcs12( site, cert_file, password=nil )
      cinfo = { :type => :pkcs12,
                :certificate_file => cert_file,
                :password => password
      }
      begin
        p12 = OpenSSL::PKCS12.new( File.read(cert_file), password)
        cinfo[:ssl_client_cert] = p12.certificate
        cinfo[:ssl_client_key] = p12.key
        cinfo[:extra_chain_certs] =  p12.ca_certs

        @client_certs[site] = cinfo
        return true
      rescue => bang
        puts bang
      end
      false

    end

    def self.set( site, cert )
      # puts "Set client cert for site #{site}"
      #puts cert.class
      #puts cert
      return false if cert.nil?
      if cert[:certificate_file].nil? or cert[:certificate_file].strip.empty?
        # puts "Removing client certificate for site #{site}"
        @client_certs.delete(site.to_sym)
        save
        return true
      end

      @client_certs[ site.to_sym ] = cert
      save
      true
    end

    def self.certs
      Marshal::load(Marshal::dump(@client_certs))
    end

    def self.certs=(client_certs)
      @client_certs = client_certs
    end

    def self.get( site )
      return nil unless @client_certs.has_key? site.to_sym
      @client_certs[ site.to_sym ]
    end

    def self.load
      certs = Watobo::DataStore.load_project_settings('ClientCertStore')
      return false if certs.nil?
      @client_certs = certs
      @client_certs.each do |site, cinfo|
        begin
          case cinfo[:type]
          when :pem
            add_pem(site, cinfo[:certificate_file], cinfo[:key_file], cinfo[:password])
          when :pkcs12
            add_pkcs12(site, cinfo[:certificate_file], cinfo[:password])
          end

        rescue => bang
          puts bang
          puts bang.backtrace
        end
      end
    end

    def self.get_subject( site )
      cert = self.get(site)
      cert.certificate.subject.to_s
    end

    def self.save
      out = {}
      @client_certs.each do |site, cinfo|
        data = {}
        # TODO: set default :save_pw to false and include switch to client cert dialog
        # TODO: use gnome-keyring as password-store
        #    - https://github.com/mvz/gir_ffi-gnome_keyring
        save_pw = cinfo.has_key?(:save_pw) ? cinfo[:save_pw] : true
        [:certificate_file, :key_file, :type, :password, :insert ].each do |k|
          val = cinfo[k]
          if k == :password and !cinfo[:password].strip.empty?
            val = save_pw ? cinfo[:password] : ''
          end
          data[k] = val
        end
        out[site] = data
      end
      Watobo::DataStore.save_project_settings('ClientCertStore', out)
    end

  end
end
