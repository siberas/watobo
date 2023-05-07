# @private 
module Watobo#:nodoc: all
  class Conversation
    include Watobo::Constants
    attr_accessor :file
    def id()
      # must be defined
    end

    def copyRequest()
      # req_copy = []
      # self.request.each do |line|
      #   req_copy.push line.clone
      # end
      orig = Utils.copyObject(@request)
      # now extend the new request with the Watobo mixins
      #copy.extend Watobo::Mixin::Parser::Url
      #copy.extend Watobo::Mixin::Parser::Web10
      #copy.extend Watobo::Mixin::Shaper::Web10
       copy = Watobo::Request.new(orig)
      return copy
    end

    private

    # def extendRequest
    #   @request.extend Watobo::Mixin::Shaper::Web10
    #   @request.extend Watobo::Mixin::Parser::Web10
    #   @request.extend Watobo::Mixin::Parser::Url
    # end

    # def extendResponse
    #   @response.extend Watobo::Mixin::Parser::Web10
    # end

    def initialize(request, response)
      @request = request.is_a?(Watobo::Request) ? request : Watobo::Request.new(request)
      @response = response.is_a?(Watobo::Response) ? response : Watobo::Response.new(response)
      @file = nil

      #  extendRequest()
      #  extendResponse()
      #Watobo::Request.create @request
      #Watobo::Response.create @response

    end

  end

end