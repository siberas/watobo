# @private
module Watobo #:nodoc: all
  def self.create_request(url, prefs = {})
    raise "obsolete, use Watobo::Request.new(url) instead"
    # unless url =~ /^https?:\/\//
    #   u = "http://#{url}"
    # else
    #   u = url
    # end

    # uri = URI.parse u
    # r = "GET #{uri.to_s} HTTP/1.1\n"
    # r << "Host: #{uri.host}\n"
    # r << "User-Agent: WATOBO\n"
    # r << "Accept: */*\n"
    # r.extend Watobo::Mixins::RequestParser
    # r.to_request
  end

  class Request < Array

    attr :data
    attr :url
    attr :header
    # attr :cookies

    include Watobo::HTTP::Cookies::Mixin
    #include Watobo::HTTP::Xml::Mixin

    def self.create request
      request.extend Watobo::Mixin::Parser::Url
      request.extend Watobo::Mixin::Parser::Web10
      request.extend Watobo::Mixin::Shaper::Web10
      # request = Request.new(request)
    end

    def copy
      c = Watobo::Utils.copyObject self
      Watobo::Request.new c
    end

    def uniq_hash()
      begin
        settings = Watobo::Conf::Scanner.to_h

        return nil if site.nil?
        hashbase = site + method + path

        get_parm_names.sort.each do |p|
          hashbase << p
          hashbase << get_parm_value(p) if settings[:non_unique_parms].include?(p)
        end

        post_parm_names.sort.each do |p|

          hashbase << p
          hashbase << post_parm_value(p) if settings[:non_unique_parms].include?(p)
        end
        # puts hashbase
        return Digest::MD5.hexdigest(hashbase)
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        return nil
      end
    end

    def clear_parameters(*locations)
      plocs = @valid_param_locations
      unless locations.empty?
        plocs = @valid_param_locations.select {|loc| locations.include? loc}
      end

      @url.clear if !@url.nil? and plocs.include?(:url)
      cookies.clear if !@cookies.nil? and plocs.include?(:cookies)
      @data.clear if !@data.nil? and plocs.include?(:wwwform)
      @json.clear if !@json.nil? and plocs.include?(:json)

    end

    def parameters(*locations, &block)
      plocs = @valid_param_locations
      locations = [] if locations.first == :all
      unless locations.empty?
        plocs = @valid_param_locations.select {|loc| locations.include? loc}
      end

      parms = []
      parms.concat @headers.parameters if plocs.include?(:headers)
      parms.concat @url.parameters if plocs.include?(:url)
      parms.concat cookies.parameters if plocs.include?(:cookies)

      parms.concat @data.parameters if !@data.nil? && plocs.include?(:wwwform)
      parms.concat @json.parameters if !@json.nil? && plocs.include?(:json)

      parms.concat @xml.parameters if !@xml.nil? && plocs.include?(:xml)
      if block_given?
        parms.each do |p|
          yield p
        end
      end
      parms
    end

    def set(parm)
      return false unless parm.respond_to?(:location)
      case parm.location
      when :data
        #
        # replace_post_parm(parm.name, parm.value)
        @data.set parm unless @data.nil?
      when :url
        @url.set parm unless @url.nil?
      when :xml
        @xml.set parm unless @xml.nil?
      when :cookie
        cookies.set parm
      when :json
        @json.set parm unless @json.nil?
      when :header
        @headers.set parm unless @headers.nil?
      end
      true
    end

    def to_s
      data = self.join
      unless has_body?
        data << "\r\n" unless data =~ /\r\n\r\n$/
      end
      data
    end

    def initialize(r)
      # super

      @valid_param_locations = [:url, :data, :wwwform, :xml, :cookies, :json, :headers, :body]
      # Base Object behaves like an empty parameter set
      @data = @json = @url = @json = @xml = nil #Watobo::HTTPData::Base.new
      if r.respond_to? :push
        #puts "Create REQUEST from ARRAY"
        self.concat r
      elsif r.is_a? String
        if r =~ /^http/
          uri = URI.parse r
          self << "GET #{uri.to_s} HTTP/1.1\r\n"
          self << "Host: #{uri.host}\r\n"
        else
          r.extend Watobo::Mixins::RequestParser
          self.concat r.to_request
        end

      end
      self.extend Watobo::Mixin::Parser::Url
      self.extend Watobo::Mixin::Parser::Web10
      self.extend Watobo::Mixin::Shaper::Web10
      self.extend Watobo::Mixin::Shaper::HttpResponse

      @url = Watobo::HTTP::Url.new(self)
      ct = content_type

      if ct =~ /\+zlib/
        dec_body = Zlib.inflate body
        setData dec_body
        set_content_type content_type.gsub(/\+zlib/, '')
        fix_content_length
      end

      case self.content_type
      when /www-form/i
        @data = Watobo::HTTPData::WWW_Form.new(self)
      when /application\/json/i
        @json = Watobo::HTTPData::Json.new(self)
      when /\/xml/i
        @xml = Watobo::HTTPData::Xml.new(self)
      else
        #puts "UNKONWN CONTENT-TYPE"
        @data = Watobo::HTTPData::WWW_Form.new(self)
      end

      @cookies = Watobo::HTTP::Cookies.new(self)
      @headers = Watobo::HTTP::Headers.new(self)
    end
  end
end