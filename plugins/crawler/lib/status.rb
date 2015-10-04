module Watobo
  module Crawler
    module Status
      include Watobo::Plugin::Crawler::Constants

      @status_lock = Mutex.new
      @request_count = 0
      @engine_status = CRAWL_NONE
      @page_size = 0
      @link_size = 0
      
      def self.reset
        @request_count = 0
        @engine_status = CRAWL_NONE
        @page_size = 0
      end

      def self.page_size=(ps)
        @status_lock.synchronize do
          @page_size= ps
        end
        true
      end

      def self.link_size=(ps)
        @status_lock.synchronize do
          @link_size= ps
        end
        true
      end

      def self.engine=(s)
        @status_lock.synchronize do
          @engine_status = s
        end
      end

      def self.engine
        e = nil
        @status_lock.synchronize do
          e = @engine_status
        end
        e
      end

      def self.inc_requests(i = 1)
        @status_lock.synchronize do
          @request_count += i
        end
      end

      def self.set(status)
        @status_lock.synchronize do

        end
      end

      def self.get
        s = {}
        @status_lock.synchronize do
          s = {
            :engine_status => @engine_status,
            :total_requests => @request_count,
            :page_size => @page_size,
            :link_size => @link_size
            # :skipped_domains => 0
          }
        end
        s
      end
    end
  end
end