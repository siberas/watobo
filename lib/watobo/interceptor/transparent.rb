# @private 
module Watobo#:nodoc: all
  module Interceptor
    module Transparent
      @nfq_drb = nil
      def self.start
        DRb.start_service
        @nfq_drb = DRbObject.new nil, "druby://127.0.0.1:9090"
      end
      
      def self.info(data)
        nfo = nil
        begin
        nfo = @nfq_drb.info(data)
        rescue => bang
          puts "! could not query nfq_server"
          puts bang
        end
        nfo
      end
    end
  end
end
