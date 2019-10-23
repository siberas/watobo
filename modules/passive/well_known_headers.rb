
# @private
module Watobo#:nodoc: all
  module Modules
    module Passive


      class Well_known_headers < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)
          @info.update(
              :check_name => 'Well-Known Headers',    # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "checks for headers to determine applications and version.",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9"   # check version
          )

          @finding.update(
              :threat => 'Information about underlying application.',        # thread of vulnerability, e.g. loss of information
              :class => "Well-Known Headers",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @tested_directories = []

          @pattern_list = [
              # pattern, CPE (Common Platform Enumeration), Name
              [ '^sap-', 'cpe:2.3:a:sap:*server', 'SAP Webserver' ],
              [ 'X-Kaltura', 'NA', 'Kaltura Video Server' ],
              [ 'Proxy-agent', 'cpe:2.3:a:oracle:iplanet_web_proxy_server', 'ORACLE iPlanet Web Proxy']

          ]


        end

        def do_test(chat)
          begin

            @pattern_list.each do |pat, cve, name|
              chat.response.headers(pat) do |header|
                match = header.split(":")[0]
                addFinding(
                    :proof_pattern => "#{match}",
                    :chat => chat,
                    :title => "#{name}"
                )

              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end
        end
      end

    end
  end
end
