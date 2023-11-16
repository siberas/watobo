module Watobo #:nodoc: all
  module Modules
    module Active
      module Auth_bypass

        class Builtin_evasions < Watobo::ActiveCheck

          include Watobo::Evasions

          @info.update(
            :check_name => 'BuiltinEvasions', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks if 403 responses can be bypassed", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :check_group => AC_GROUP_GENERIC,
            :version => "1.0" # check version
          )

          @finding.update(
            :threat => '', # thread of vulnerability, e.g. loss of information
            :class => "BuiltinEvasions", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :rating => VULN_RATING_CRITICAL,
            :measure => "Check your authentication implementation",
            :details => '',
            :type => FINDING_TYPE_VULN # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          def initialize(session_name = nil, prefs = {})
            #  @project = project
            super(session_name, prefs)
            @known_responses = []
          end

          def reset()
            @known_responses = []
            @@found = false
          end

          def found
            @@found
          end

          def found=(state)
            @@found = state
          end

          def generateChecks(chat)
            begin

              status = chat.response.status_code
              need_evasion = (status =~ /^4\d\d/ && status != '404')

              puts "Need Evasion: #{need_evasion ? 'YES' : 'NO' }"
              if need_evasion
                evasion_handlers.each do |handler|
                  sample = chat.copyRequest

                  test_request = test_response = nil
                  handler.run(sample) do |test|
                    checker = proc {
                      fexist, test_request, test_response = fileExists?(test)

                      if fexist == true
                        found = true
                        rhash = Watobo::Utils.responseHash(test_request, test_response)
                        unless @known_responses.include?(rhash)
                          @known_responses << rhash
                          addFinding(test_request, test_response,
                                     :test_item => handler.class.to_s,
                                     # :proof_pattern => "#{Regexp.quote(uri)}",
                                     :check_pattern => "#{Regexp.quote(test_response.status)}",
                                     :chat => chat,
                                     :threat => "depends on the file ;)",
                                     :title => "[#{handler.class.to_s}]"
                          )

                          f= {
                            :test_item => handler.class.to_s,
                            # :proof_pattern => "#{Regexp.quote(uri)}",
                            :check_pattern => "#{Regexp.quote(test_response.status)}",
                            :chat => chat,
                            :threat => "depends on the file ;)",
                            :title => "[#{handler.class.to_s}]"
                          }
                          puts JSON.pretty_generate(f)
                          puts test_response
                        end
                      end
                      [test_request, test_response]

                    }
                    yield checker
                  end
                end

              end

            rescue => bang

              puts "ERROR!! #{Module.nesting[0].name} "
              puts "chatid: #{chat.id}"
              puts bang
              puts

            end
          end

        end
      end
    end
  end
end
