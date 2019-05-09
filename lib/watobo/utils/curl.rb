module Watobo
  module Utils
    module Curl
      REMOVE_HEADERS=%w( Content-Length Connection ).map{|h| h.downcase }
      def self.create_request(request)
        cURL = [ 'curl -X ' + request.method.upcase ]
        cURL << request.url_string
        request.headers.each do |h|
          hname = h.gsub(/:.*/,'').downcase
          cURL << '-H "' + h.strip + '"' unless REMOVE_HEADERS.include?(hname)
        end

        cURL.join(" \\\n   ")

      end
    end
  end
end