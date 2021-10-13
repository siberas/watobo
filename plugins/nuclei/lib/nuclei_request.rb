module Watobo #:nodoc: all
  module Plugin
    class NucleiScanner


      class NucleiRequest

        MATCHER_CONDITION_OR = 0x00
        MATCHER_CONDITION_AND = 0x01

        attr :collection, :template

        attr_accessor :responses


        def match?(responses = nil)
          check_responses = response.nil? ? @responses : responses
          @nuclei_matcher.match?(check_responses)
        end

        def has_matcher?
          !@nuclei_matcher.nil?
        end

        def each(base, &block)
          req_collection = []
          raw_requests(base) do |raw|

          end
          req_collection
        end

        # @return all possible Requests for each request definition
        # no §param§ or {{expr}} are replaced here
        # @param base [Watobo::Request] is needed to give all required target information,
        # e.g. Hostname or BaseURL
        # Example
        # method: POST
        # paths:
        #   - /aaa/xxx
        #   - /bbb/yyy
        #
        # will result in two single requests
        def raw_requests(base, &block)
          raise "no generate method defined"
        end

        # @param nuclei_request [Hash] request definition
        #
        # @param base [String|Array]
        def initialize(request_template, payload=nil)

          @nuclei_matcher = nil
          @template = request_template

          # collection will store all request definitions
          @collection = []
          @payload = payload

          binding.pry

          @responses = []

          # req_condition is needed for matcher behaviour
          # if true all responses will be evaluated
          # Nuclei:
          # Request condition allows to check for condition between multiple requests for writing complex checks and exploits
          # involving multiple HTTP request to complete the exploit chain.
          # with DSL matcher, it can be utilized by adding req-condition: true and numbers as suffix with respective attributes,
          # status_code_1, status_code_3, andbody_2 for example.
          @req_condition = false

          @matchers_condition = MATCHER_CONDITION_OR

          create_matcher
          apply_template
        end

        private


        # polish is replacing all expressions (e.g. {{base64('admin')}} )
        # @param request [Watobo::Request]
        # @return final request ready to send over the wire
        def polish(request)

        end

        def apply_template
          raise "apply_template not defined"
        end

        def create_matcher
          return nil unless !!@template['matchers']

          if !!template['matchers-condition']
            @matchers_condition = MATCHER_CONDITION_AND if template['matchers-condition'].match?(/and/i)
          end
          @nuclei_matcher = NucleiScanner::NucleiMatcher.new template['matchers']

        end


      end


      class NucleiBaseRequest < NucleiRequest


        def raw_requests(base, &block)
          gs = []
          url = base.url.to_s
          url.gsub!(/\/$/, '')

          @collection.each do |path|
            request = base.copy
            npath = path.gsub('{{BaseURL}}', '')

            new_path = base.path.match?(/\/$/) ? base.path.gsub(/\/$/, '') : base.path
            new_path << ( npath.match?(/^\//) ? npath : "/#{path}" )

            request.method = template['method']

            request.path = new_path


            if !!template['headers']
              template['headers'].each do |h|
                request.add_header h
              end
            end

            if !!template['body']
              request.set_body template['body']
            end


            yield request if block_given?
            gs << request
          end
          gs
        end

        def initialize(request_template)
          super(request_template)
        end

        private

        #

        def apply_template
          raise "bad template for #{self}" unless !!template['method']
          template['path'].each do |c|
            @collection << c
          end
        end


      end

      class NucleiRawRequest < NucleiRequest


        def initialize(request_template)
          super(request_template)

        end

        def apply_template
          raise "bad template for #{self}" unless !!template['raw']
          template['raw'].each do |c|
            @collection << c
          end
        end

        def raw_requests(base, &block)
          gs = []
          url = base.url.to_s
          url.gsub!(/\/$/, '')
          @collection.each do |raw|
            raw.gsub!(/^(\w+ )(.*)/, "\\1#{url}\\2")

            raw.extend Watobo::Mixins::RequestParser

            rr = raw.to_request
            rr.set_header 'Host', base.host
            yield rr if block_given?
            gs << rr
          end
          gs
        end
      end
    end
  end
end