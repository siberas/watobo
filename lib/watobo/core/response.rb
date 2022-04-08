# @private 
module Watobo #:nodoc: all
  class Response < Array
    def self.is_html?

    end

    def self.is_json?

    end


    def self.create(response)
      raise ArgumentError, "Array Expected." unless response.is_a? Array
      response.extend Watobo::Mixin::Parser::Url
      response.extend Watobo::Mixin::Parser::Web10
      response.extend Watobo::Mixin::Shaper::Web10
      response.extend Watobo::Mixin::Shaper::HttpResponse
    end

    def to_s
      # crash
      #data = self.join
      #
      # empty content
      # data = self.map{|e| e.force_encoding('UTF-8')}.join
      begin
        data = self.map { |e| e.force_encoding('ASCII-8BIT') }.join


        unless has_body?
          data << "\r\n" unless data =~ /\r\n\r\n$/
        end
        return data
      rescue => bang
        puts bang
        puts bang.backtrace
        binding.pry if $DEBUG
      end
    end


    def data
      @data
    end

    def copy
      c = Watobo::Utils.copyObject self
      Watobo::Request.new c
    end

    def initialize(r)
      if r.respond_to? :concat
        #puts "Create REQUEST from ARRAY"
        self.concat r
      elsif r.is_a? String
        raise ArgumentError, "Need Array"
      end
      self.extend Watobo::Mixin::Parser::Url
      self.extend Watobo::Mixin::Parser::Web10
      self.extend Watobo::Mixin::Shaper::Web10
      self.extend Watobo::Mixin::Shaper::HttpResponse

      if content_type =~ /(html|text)/
        self.extend Watobo::Parser::HTML
      end

    end
  end
end