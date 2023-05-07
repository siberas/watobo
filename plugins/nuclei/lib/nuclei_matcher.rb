module Watobo #:nodoc: all
  module Plugin
    class NucleiScanner
      class NucleiMatcher

        MATCHER_TYPE_OR = 0x00
        MATCHER_TYPE_AND = 0x01

        MATCHER_ENCODING_NONE = 0x00
        MATCHER_ENCODING_HEX = 0x01

        class Matcher

          attr :condition, :negative, :encoding, :part

          def match?(responses)

            responses.each do |resp|
              parts = get_part(part, resp)
              results = match_results(parts)
              if condition == MATCHER_TYPE_OR
                return results.inject(false) { |i, v| i || v }
              end
              return results.inject(true) { |i, v| i && v }

            end
          end

          # checks for part definition
          # if no part definition is found an error is raised
          def need_part!
            raise "No Part Definition Found!" unless @part
          end


          def initialize(prefs)
            @condition = MATCHER_TYPE_OR
            @negative = false
            @encoding = MATCHER_ENCODING_NONE
            @part = nil
            @type = nil

            @part = prefs['part'] if !!prefs['part']
            @part = 'all' if part.nil?

            if !!prefs['condition'] && prefs['condition'] =~ /and/i
              @condition = MATCHER_TYPE_AND
            end

            if !!prefs['negative'] && prefs['negative']
              @negative = true
            end

            if !!prefs['encoding'] && prefs['encoding'] =~ /hex/i
              @encoding = MATCHER_ENCODING_HEX
            end
          end

          private

          def match_results(parts)
            binding.pry
            raise "No match_result method defined for #{self.class}"
          end

          # @return [Array] of relevant parts
          # @param [String] the name of the part
          # @param [Watobo::Response]
          def get_part(part_name, response)
            puts "+ get part name >> #{part_name}"
            part = []
            if part_name =~ /status_code/
              part << response.status_code.to_i
            elsif part_name =~ /^status$/
              part << response.status_code.to_i
            elsif part_name =~ /all_headers/
              part.concat response.headers
            elsif part_name =~ /body/
              part << response.body.to_s
            elsif part_name =~ /raw/
              part << response.to_s
            else
              # check if part_name is a header definition
              # e.g. content_length
              e = part_name.split('-')
              e.map! { |x| x.capitalize }
              part.concat response.headers(e.join('-'))
            end

            # if encoding is hex we encode the parts
            # we don't decode the pattern because of possible string encoding problems
            if encoding == MATCHER_ENCODING_HEX
              part.map! { |p| p.unpack("H*")[0] }
            end

            part
          end
        end

        # matchers:
        #   # Match the status codes
        #   - type: status
        #     # Some status codes we want to match
        #     status:
        #       - 200
        #       - 302
        class MatcherStatus < Matcher
          attr :status_values

          def initialize(prefs)
            super(prefs)
            @part = 'status'
            @status_values = prefs['status']

          end

          private

          def match_results(parts)
            results = []
            status_values.each do |s|

              parts.each do |p|
                puts "[#{self}] match status: #{s} <> #{p}"
                m = s.to_i == p.to_i
                results << (negative ? !m : m)
              end
            end
            results
          end
        end

        class MatcherSize < Matcher
          attr :size

          def initialize(prefs)
            super(prefs)
            need_part!
          end

          private

          def match_results(parts)
            results = []
            parts.each do |p|
              puts "[#{self}] match size: #{size} <> #{p.length}"
              m = size.to_i == p.length.to_i
              results << (negative ? !m : m)
            end
            results
          end
        end

        class MatcherRegex < Matcher
          def initialize(prefs)
            super(prefs)
          end
        end

        # matchers:
        #   - type: binary
        #     binary:
        #       - "504B0304" # zip archive
        #       - "526172211A070100" # rar RAR archive version 5.0
        #       - "FD377A585A0000" # xz tar.xz archive
        #     condition: or
        #     part: body
        class MatcherBinary < Matcher
          def initialize(prefs)
            super(prefs)
          end
        end

        # matchers:
        #   - type: word
        #     encoding: hex
        #     words:
        #       - "50494e47"
        #     condition: or
        #     part: body
        class MatcherWord < Matcher
          attr :words


          def initialize(prefs)
            super(prefs)
            @words = prefs['words']
          end

          private

          def match_results(parts)
            results = []
            words.each do |w|

              parts.each do |p|
                puts "[#{self}] match ? #{p} <> #{w}"
                m = p.match?(/#{Regexp.quote(w)}/i)
                results << (negative ? !m : m)
              end
            end
            results
          end
        end

        #     req-condition: true
        #     matchers:
        #       - type: dsl
        #         dsl:
        #           - "status_code_1 == 404 && status_code_2 == 200 && contains((body_2), 'secret_string')"
        class MatcherDsl < Matcher
          def initialize(template)
            puts "+ MatcherDsl created"
            super(template)
            @dsl = template['dsl']
          end

          def match?(responses)
            @responses = responses
            dsl_eval(@dsl)
          end

          def contains(location, pattern)
            location.match? /#{Regexp.quote(pattern)}/i
          end

          def status_code(index = -1)
            @responses[index].status_code.to_i
          end

          def mmh3(str)

          end

          def base64_py(str)

          end

          def tolower(str)
            str.downcase
          end

          def all_headers(index = -1)
            @responses[index].headers.join
          end

          def body(index = -1)
            @responses[index].body
          end

          private

          def dsl_eval(dsl_cmds)
            dsl_results = []
            dsl_cmds.each do |cmd|
              puts "+ executing command: #{cmd}"
              binding.pry
              r = eval(cmd)
              puts r
              dsl_results << r
            end

            if condition == MATCHER_TYPE_OR
              return dsl_results.inject(false) { |i, v| i || v }
            end

            return dsl_results.inject(true) { |i, v| i && v }
          end

          def method_missing(name, *args, &block)
            #  puts "!!! method missing !!!\n>> #{name.to_s}\n--"
            if name.to_s =~ /(.*)_(\d+)/
              # decrement reference count by 1, because reference starts with 1 and
              # not array-like with 0
              return self.send($1.to_sym, ($2.to_i - 1))
            end
            super
          end


        end


        def initialize(template)
          @matchers = []
          @matcher_condition = MATCHER_TYPE_OR
          template.each do |m|
            mtype = m['type']

            if mtype =~ /^dsl$/i
              @matchers << MatcherDsl.new(m)
            elsif mtype =~ /^word$/i
              @matchers << MatcherWord.new(m)
            elsif mtype =~ /^status$/i
              @matchers << MatcherStatus.new(m)
            elsif mtype =~ /^size$/i
              @matchers << MatcherSize.new(m)
            elsif mtype =~ /^regex$/i
              @matchers << MatcherWord.new(m)
            elsif mtype =~ /^binary$/i
              @matchers << MatcherBinary.new(m)
            end
          end
        end

        def match?(responses)
          results = []
          @matchers.each do |matcher|
            results << matcher.match?(responses)
          end

          puts "[Matcher] match?"
          puts results

          if @matcher_type == MATCHER_TYPE_OR

            return results.inject(false) { |i, v| i || v }
          end

          return results.inject(true) { |i, v| i && v }

        end

      end
    end
  end
end
