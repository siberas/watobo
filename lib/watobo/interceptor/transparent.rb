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
        @nfq_drb.info(data)
      end
    end
  end
end