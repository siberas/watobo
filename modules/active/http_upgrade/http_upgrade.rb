# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Http_upgrade
        class Http_upgrade < Watobo::ActiveCheck
          # TODO: make different checks for better adoption of spedific headers
=begin
Infos: https://en.wikipedia.org/wiki/HTTP/1.1_Upgrade_header

Example: JBoss Remoting
GET / HTTP/1.1
Sec-JbossRemoting-Key: f36M+fZYgDQQplAh5sVOYA==
Upgrade: jboss-remoting
Host: scal204:8280
Connection: upgrade

---

GET http://demos.kaazing.com/echo?.kl=AL HTTP/1.1
Host: demos.kaazing.com
Connection: Upgrade
User-Agent: Mozilla/5.0 (X11; Fedora; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36
Upgrade: WebSocket
Sec-WebSocket-Version: 13
Sec-WebSocket-Key: V29MSM/pNjdXWKzT1ZgUQ==


=end


          @@tested_paths = []
          @@upgrade_protocols = %w( jboss-remoting websocket )

          @@upgrade_headers = {}
          @@upgrade_headers['jboss-remoting'] = {
              'Sec-JbossRemoting-Key' => lambda { Base64.strict_encode64(SecureRandom.hex(6))}
          }
          @@upgrade_headers['websocket'] = {
              'Sec-WebSocket-Version' => lambda { "13"},
              'Sec-WebSocket-Key' => lambda { Base64.strict_encode64(SecureRandom.hex(6))}
          }


          threat = <<'EOF'

EOF
          measure = "check if protocol upgrade is intended or needed"

          @info.update(
              :check_name => 'HTTP Upgrade', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => 'HTTP Protocol',
              :description => "Checks if connection is able to upgrade, e.g. to websockets or jboss-remoting", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "HTTP Upgrade", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_HINT, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)
          end

          def reset()
            @@tested_paths.clear
          end

          def generateChecks(chat)

            begin
              file = chat.request.file
              return nil if @@tested_paths.include? file
              @@tested_paths << file

              @@upgrade_protocols.each do |up|
                checker = proc {

                  test_request = nil
                  test_response = nil

                  # IMPORTANT!!!
                  # use copyRequest(chat) for cloning the original request
                  t_request = chat.copyRequest
                  t_request.setHeader('Upgrade', up)
                  t_request.setHeader('Connection', 'upgrade')

                  # add specifig headers
                  @@upgrade_headers[up].each do |k,v|
                    t_request.setHeader(k, v.call)
                  end

                  status, test_request, test_response = doRequest(t_request, :no_connection_close => true, :skip_body => true)

                  unless test_response.nil?

                    upgrade_header = test_response.headers(/^Upgrade/).first
                    connection_header = test_response.headers(/^Connection/).first

                    unless upgrade_header.nil? && connection_header.nil?
                      if upgrade_header =~ /#{up}/i
                        addFinding(test_request, test_response,
                                   :threat => "Found that HTTP is upgradeable",
                                   :measure => "check if intended",
                                   :check_pattern => "#{up}",
                                   :proof_pattern => "#{up}",
                                   :test_item => up,
                                   :type => FINDING_TYPE_HINT,
                                   :class => "Information",
                                   :chat => chat,
                                   :title => "HTTP Upgrade #{up}"
                        )
                      end
                    end
                  end
                  [test_request, test_response]
                }
                yield checker
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
