# @private 
module Watobo#:nodoc: all
  module Crawler
    class PageBag
      attr :page, :depth
      def initialize(page, depth)
        @page = page
        @depth = depth
      end
    end

    class LinkBag
      attr :link, :depth
      def initialize(link, depth)
        @link = link
        @depth = depth
      end
    end
  end
end    