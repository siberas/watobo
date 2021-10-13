# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Http_header


        class Http_x_headers < Watobo::ActiveCheck

          @@tested_paths = []

          details = <<EOD
This check is injecting HTTP headers which are known to be able to manipulate the request flow of Loadbalancers or Reverse-Proxies.
EOD

          @info.update(
              :check_name => 'X-HTTP Header Injection', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks if http routing can be changed.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :check_group => AC_GROUP_GENERIC,
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => 'Packet routing might be manipulated, which could lead to url filter evasion.', # thread of vulnerability, e.g. loss of information
              :class => "X-HTTP-Header", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :rating => VULN_RATING_INFO,
              :measure => "Filter/remove injected headers.",
              :details => details,
              :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name = nil, prefs = {})
            #  @project = project
            super(session_name, prefs)
            @@response_hashes = []
            @@tested_paths = []
            @inj_headers = %w( X-Forwarded-For X-Host X-Forwarded-Server X-Forwarded-Host X-Forwarded-Scheme X-Original-URL X-Rewrite-URL )

          end

          def reset()
            @@tested_paths.clear
            @@response_hashes.clear
          end


          def generateChecks(chat)
            @inj_headers.each do |inj_header|
              checker = proc {
                begin
                  test_request = nil
                  test_response = nil
                  test_request = chat.copyRequest

                  inj_host = "#{checkid}.#{Watobo::Conf::Scanner.dns_sensor}"
                  test_request.set_header(inj_header, inj_host)

                  t_request, t_response = doRequest(test_request, :default => true)

                  unless Watobo::Utils.compare_responses(t_response, chat.response)

                    addFinding(t_request, t_response,
                               :check_pattern => inj_header,
                               :chat => chat,
                               :title => "#{inj_header} - #{t_request.path}"
                    )
                  end
                rescue => bang

                  puts "ERROR!! #{Module.nesting[0].name} "
                  puts "chatid: #{chat.id}"
                  puts bang
                  puts

                end
                [t_request, t_response]
              }
              yield checker
            end
          end
        end
      end
    end
  end
end
