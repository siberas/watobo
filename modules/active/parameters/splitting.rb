# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Parameters


        class Splitting < Watobo::ActiveCheck

          threat = <<'EOF'
Parameter Splitting might be used to bypass XSS filters.
EOF

          measure = "parameter splitting should not be possible."

          @info.update(
              :check_name => 'Parameter Splitting', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_PARAMS,
              :description => "Check for every parameter if response contains XSS'able content.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Reflected XSS", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_HINT, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_INFO,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)
          end


          def generateChecks(chat)
            #
            #  Check GET-Parameters
            #
            begin

              if chat.response.content_type =~ /html/i and chat.response.has_body?
                chat.request.parameters(:url, :www_form) do |testparm|

                  parm = testparm.copy
                  checker = proc {
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest

                    # build check parameter <prefix></script><suffix>
                    v1 = SecureRandom.hex(3)
                    v2 = SecureRandom.hex(3)

                    pname = parm.name

                    parm.value = v1
                    test.set parm

                    if parm.location == :url
                      test.add_url_parm pname, v2
                    else
                      test.add_post_parm pname, v2
                    end

                    test_request, test_response = doRequest(test)


                    if !!test_response and test_response.has_body?
                      if test_response.body =~ /#{v1}.*#{v2}/i
                        finding_class = "Parameter Splitting [#{parm.location.to_s}]"
                        addFinding(test_request, test_response,
                                   :check_pattern => "#{v1}.*#{v2}",
                                   :proof_pattern => "#{v1}.*#{v2}",
                                   :test_item => parm.name,
                                   :class => finding_class,
                                   :chat => chat,
                                   :title => "[#{parm.name}] - #{test_request.path}"
                        )
                      end
                    end
                    #@project.new_finding(:short_name=>"#{parm}", :check=>"#{check}", :proof=>"#{pattern}", :kategory=>"XSS-Post", :type=>"Vuln", :chat=>test_chat, :rating=>"High")
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
  end
end
