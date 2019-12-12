# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Hrs


        class Te_cl < Watobo::ActiveCheck

          @info.update(
              :check_name => 'HRS TE-CL', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "HTTP Request Smuggling with Type-Encoding/Content-Length combination", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0", # check version
                   :check_group => 'HRS'
          )

          @finding.update(
              :threat => 'Access to restricted files', # thread of vulnerability, e.g. loss of information
              :class => "HTTP Request Smuggling", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
          )


          def initialize(session_name=nil, prefs={})
            #  @project = project
            super(session_name, prefs)

          end

          def reset()

          end

          def generateChecks(chat)

            begin

              checker = proc {
                test_request = nil
                test_response = nil

                # do a reference request for later comparation
                ref_request = chat.copyRequest
                request, ref_response = doRequest(ref_request, :default => true)


                test_request = chat.copyRequest

                test_request.setMethod 'POST'
                # remove connection header
                test_request.removeHeader 'Connection'
                test_request.setHeader 'Content-Type', 'application/x-www-form-urlencoded'
                test_request.setHeader 'Transfer-Encoding', 'chunked'


                smuggle = "GET /fourOfour.txt HTTP/1.1\r\nHost: localhost\r\n\r\n"
                body = "0\r\n" + smuggle

                test_request.setHeader 'Content-Length', "#{body.length}"
                test_request.setBody body

                # check order of headers
                te_index = test_request.index{|h| h =~ /Transfer\-Encoding/ }
                cl_index = test_request.index{|h| h =~ /Content\-Length/ }

                # CL should be before TE
                if te_index < cl_index
                  dummy = test_request[te_index]
                  test_request[te_index] = test_request[cl_index]
                  test_request[cl_index] = dummy
                end

                test_request, test_response = doRequest(test_request,
                                                        :no_connection_close => true,
                                                        :update_contentlength => false
                )


                puts ">>> HRS <<<<"
                puts test_request
                puts '---'
                puts test_response
                puts test_response.class
                puts test_response.empty?

                if test_response.status_code != ref_response.status_code  then
                  addFinding(test_request, test_response,
                             :check_pattern => "#{body}",
                            # :test_item => file,
                             :proof_pattern => "#{test_response.status_code}",
                             :chat => chat,
                             :title => "[ HRS ]"
                  #:debug => true
                  )
                end
                [test_request, test_response]
              }
              yield checker

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
