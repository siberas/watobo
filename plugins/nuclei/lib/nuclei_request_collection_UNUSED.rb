module Watobo #:nodoc: all
  module Plugin
    class NucleiScanner
      class NucleiRequestCollection
        attr :collection

        def initialize(request_template)
          @template = request_template
          @collection = []
          @responses = []
        end

        private
        def parse_template
          if !!r['raw']
            r['raw'].each do |raw|
              requests << Watobo::Plugin::NucleiScanner::NucleiRawRequest.new(r, base_request)
            end
          else
            requests << Watobo::Plugin::NucleiScanner::NucleiBaseRequest.new(r, base_request.url.to_s)
          end
        end
      end
    end

  end
end