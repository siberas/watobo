 @private 
module Watobo#:nodoc: all
  module ClientCertStore#:nodoc: all
    @client_certs = {}
    
#    :ssl_client_cert
#    :ssl_client_key
#    :extra_chain_certs
    
    def self.clear
      @client_certs.clear
    end
    
    def self.set( site, cert )
      return false if cert.nil?
      @client_certs[ site.to_sym ] = cert
      true
    end
    
    def self.get( site )
      return nil unless @client_certs.has_key? site.to_sym
      @client_certs[ site.to_sym ]
    end
    
end
end