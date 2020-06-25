# @private 
module Watobo#:nodoc: all
  module Interceptor
    INTERCEPT_NONE = 0x00
    INTERCEPT_REQUEST = 0x01
    INTERCEPT_RESPONSE = 0x02
    INTERCEPT_BOTH = 0x03

    REWRITE_NONE = 0x00
    REWRITE_REQUEST = 0x01
    REWRITE_RESPONSE = 0x02
    REWRITE_BOTH = 0x04

    INTERCEPT_DEFAULT_PORT = 8081

    MODE_REGULAR = 0x01
    MODE_TRANSPARENT = 0x02


    @proxy_mode ||= MODE_REGULAR
    @intercept_mode ||= INTERCEPT_NONE
    @rewrite_mode ||= REWRITE_NONE
    @egress_enabled ||= false

    @proxy = nil
    #@proxy_mode = Watobo::Conf::Interceptor.proxy_mode if Watobo::Conf::Interceptor.respond_to? :proxy_mode
    def self.proxy_mode
      @proxy_mode
    end



    def self.proxy_mode=(mode)
      @proxy_mode = mode
    end

    def self.rewrite_mode
      @rewrite_mode
    end

    def self.rewrite_mode=(mode)
      @rewrite_mode = mode
    end

    def self.intercept_mode
      @intercept_mode
    end

    def self.intercept_mode=(mode)
      @intercept_mode = mode
    end

    def self.transparent?
      return true if ( @proxy_mode & MODE_TRANSPARENT ) > 0
      return false
    end

    def self.intercept_requests?
      return true if ( @intercept_mode & INTERCEPT_REQUEST ) > 0
      return false
    end

    def self.intercept_responses?
      return true if ( @intercept_mode & INTERCEPT_RESPONSE ) > 0
      return false
    end

    def self.rewrite_requests?
      return true if ( @rewrite_mode & REWRITE_REQUEST ) > 0
      return false
    end

    def self.rewrite_responses?
      return true if ( @rewrite_mode & REWRITE_RESPONSE ) > 0
      return false
    end

    def self.active?
      return false if @proxy.nil?
      return true
    end

    def self.start
     # @proxy = Watobo::InterceptProxy.new()

      @proxy = Watobo::Interceptor::Proxy.start()
      puts "DEBUG: Proxy running" if $DEBUG
    #   puts "* set www_auth for interceptor"
    #   puts YAML.dump(@project.settings[:www_auth])
    #@proxy.www_auth = Watobo.project.settings[:www_auth] unless Watobo.project.nil?
    end

    def self.proxy
      @proxy
    end

    def self.stop
      @proxy.stop
      @proxy = nil
    end

  end
end
