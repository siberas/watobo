# @private 
module Watobo#:nodoc: all
  module Crawler
    class Grabber
      def get_page(linkbag)
        begin
          return nil if linkbag.nil?
          return nil unless linkbag.respond_to? :link
          page = nil

          uri = linkbag.link
          uri = linkbag.link.uri if linkbag.link.respond_to? :uri

          unless @opts[:head_request_pattern].empty?
            pext = uri.path.match(/\.[^\.]*$/)
            unless pext.nil?
              if pext[0] =~ /\.#{@opts[:head_request_pattern]}/i
              page = @agent.head uri
              end
            end
          end

          page = @agent.get uri if page.nil?
          
          Watobo::Crawler::Status.inc_requests

          sleep(@opts[:delay]/1000.0).round(3) if @opts[:delay] > 0
          return nil if page.nil?
          return PageBag.new( page, linkbag.depth+1 )
        rescue => bang
          puts bang #if $DEBUG
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def run
        @grab_thread = Thread.new(@link_queue, @page_queue){ |lq, pq|
          loop do
            begin
              #link, referer, depth = lq.deq
              link = lq.deq
              next if link.depth > @opts[:max_depth]
              page = get_page(link)
              pq << page unless page.nil?

            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end
        }
         @grab_thread
      end

      def initialize(link_queue, page_queue, opts = {} )
        @link_queue = link_queue
        @page_queue = page_queue
        @opts = opts
        @grab_thread = nil
        
        begin
          @agent = Crawler::Agent.new(@opts)
    
        rescue => bang
          puts bang
          puts bang.backtrace
        end

      end

    end
  end
end
