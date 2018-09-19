# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Template_injection


        class Tinject < Watobo::ActiveCheck

          threat = <<'EOF'

EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'Simple Template Injection Checks', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_TEMPLATE,
              :description => "Check for template injection vulnerabilities.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Template Injection", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)

            @evasions = ["%0a", "%00"]

            @markers = []
            @markers << %w( { } )
            @markers << %w( {{ }} )
            @markers << %w( ${ } )
            @markers << %w( <% %> )
            @markers << %w( <%= %> )
            @markers << %w( [% %] )
            @markers << %w( [%= %] )

          end


          def generateChecks(chat)
            #
            #  Check GET-Parameters
            #
            begin


              @parm_list = chat.request.parameters(:data, :url, :json)
              @parm_list.each do |parm|
                checks = []
                checks.concat @markers

                @evasions.each do |e|
                  checks.concat @markers.map {|m| ["#{e}#{m[0]}", m[1]]}
                end

                checks.each do |check|
                  checker = proc {
                    test_request = nil
                    test_response = nil

                    inj_val = '666 * 666'
                    inj = "#{check[0]} #{inj_val} #{check[1]}"
                    pattern = eval(inj_val).to_s

                    puts pattern

                    test = chat.copyRequest

                    parm.value = inj
                    if parm.location == :url
                      parm.value = URI.escape(inj)
                    end
                    test.set parm

                    puts test

                    test_request, test_response = doRequest(test)

                    puts test_response


                    if test_response.join =~ /(#{pattern})/i
                      match = $1

                      addFinding(test_request, test_response,
                                 :check_pattern => "#{check}",
                                 :proof_pattern => "#{match}",
                                 :test_item => parm,
                                 :chat => chat,
                                 :title => "[#{parm}] - #{test_request.path}"
                      )
                    end

                    [test_request, test_response]
                  }
                  yield checker
                end
              end
            end

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            puts "ERROR!! #{Module.nesting[0].name}"
            raise


          end
        end

      end

    end
  end
end

