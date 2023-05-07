# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Ssti


        class Ssti_simple < Watobo::ActiveCheck

          threat = <<'EOF'

EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'Simple Template Injection Checks', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_SSTI,
              :description => "Check for template injection vulnerabilities.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => AC_GROUP_SSTI, # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)

            @evasions = [ "%0d0a", "%0a", "%00"]

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
              @parm_list.each do |param|
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

                    test = chat.copyRequest
                    parm = param.copy

                    parm.value = inj
                    if parm.location == :url
                      parm.value = CGI.escape(inj)
                    end
                    test.set parm

                    test_request, test_response = doRequest(test)


                    if test_response.join =~ /(#{pattern})/i
                      puts '!!! GOTCHA !!!! FOUND SSTI Vulnerability' if $VERBOSE
                      match = $1

                      addFinding(test_request, test_response,
                                # :check_pattern => "#{Regexp.quote(parm.value)}",
                                 :check_pattern => "#{parm.value}",
                                 :proof_pattern => "#{match}",
                                 :test_item => "#{parm.name}",
                                 :chat => chat,
                                 :title => "[#{parm.name}] - #{test_request.path}"
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

