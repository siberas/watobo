module Watobo #:nodoc: all
  module Plugin
    class NucleiScanner
      # NucleiCheck
      # each check consists of multiple request collections
      # e.g. on raw-request definition can have multiple sub-requests which are grouped up in one collection
      # Each collection has it's own matcher definition
      #
      class NucleiCheck < Watobo::ActiveCheck
        attr :filename, :template, :requests

        def initialize(project, template_file, prefs)
          super(project, prefs)

          @filename = template_file
          @template = YAML.load_file template_file
          # dirty workaround
          # TODO: Fix this
          @finding = self.class.instance_variable_get("@finding")
          @info = self.class.instance_variable_get("@info")
          @info[:check_name] = @template['id'] + ': ' + @template['info']['name']
          @info[:description] = @template['info']['reference']

          @requests = []
          @matcher = nil

          # binding.pry
          update_rating

          init_requests
          # create_matcher

        end


        # @param chat [Watobo::Chat] is only used to supply the base request
        def generateChecks(chat)

          responses = []

          requests.each do |nuclei_request|
            checker = proc {


              nuclei_request.each(chat.copyRequest) do |test_request|

                request, response = doRequest(test_request)

                nuclei_request.responses << response

              end

              # if number responses is the same as the number of requests
              # we have a finding
              if nuclei_request.match?
                addFinding(requests.last, responses.last,
                           :test_item => "nuclei-template",
                           :chat => chat
                )
              end
            }
            yield checker
          end
        end

        private

        def update_rating
          severity = @template['info']['severity'] ? @template['info']['severity'] : 'low'
          @finding[:type] = severity.match?(/info/i) ? FINDING_TYPE_INFO : FINDING_TYPE_VULN
          @finding[:rating] = VULN_RATING_LOW
          @finding[:rating] = VULN_RATING_MEDIUM if severity.match?(/medium/i)
          @finding[:rating] = VULN_RATING_HIGH if severity.match?(/high/i)
          @finding[:rating] = VULN_RATING_CRITICAL if severity.match?(/criti/i)

        end

        def init_requests
          requests = []
          return [] unless @template['requests']
          @template['requests'].each do |r|
            # puts "+ request >>"
            if !!r['raw']
              @requests << NucleiRawRequest.new(r)
            else
              @requests << NucleiBaseRequest.new(r)
            end
          end
          requests
        end

      end
    end
  end
end
