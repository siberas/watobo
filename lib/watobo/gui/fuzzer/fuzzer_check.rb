# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer

      class FuzzerCheck < Watobo::ActiveCheck

        def initialize(project, fuzzer_list, filter_list, requestEditor, prefs = {})
          super(project.object_id, prefs)
          @fuzzer_list = fuzzer_list
          @requestEditor = requestEditor
          @filter_list = filter_list
          @prefs = prefs
        end


        def fuzzels(fuzzers, index = 0, result = nil)
          begin
            unless fuzzers[index].nil?
              fuzzers[index].run(result) do |fuzz|
                if index < fuzzers.length - 1
                  fuzzels(fuzzers, index + 1, fuzz) do |sr|
                    yield sr
                  end
                else
                  yield fuzz
                end
              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end


        def reset()

        end

        def generateChecks(chat)
          unless @fuzzer_list.empty?
            fuzzels(@fuzzer_list) do |fuzzle|
              test_fuzzle = Hash.new
              test_fuzzle.update YAML.load(YAML.dump(fuzzle))
              checker = proc {
                #puts test_fuzzle
                fuzz_request = @requestEditor.parseRequest(test_fuzzle)
                fuzz_request.extend Watobo::Mixin::Shaper::Web10
                fuzz_request.extend Watobo::Mixin::Parser::Web10
                fuzz_request.extend Watobo::Mixin::Parser::Url

                test_request, test_response = doRequest(fuzz_request, @prefs)

                notify(:stats, test_response)

                notify(:fuzzer_match, test_fuzzle, test_request, test_response, test_response.join) if @filter_list.empty?

                @filter_list.each do |f|
                  matches = f.func.call(test_response) if f.func.respond_to? :call
                  matches.each do |match|
                    notify(:fuzzer_match, test_fuzzle, test_request, test_response, match)
                  end
                end

                [test_request, test_response]
              }
              yield checker
            end
          end
        end
      end
    end

  end
end
