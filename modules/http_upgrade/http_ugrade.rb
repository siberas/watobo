# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Http_upgrade
        class Http_upgrade
=begin
Infos: https://en.wikipedia.org/wiki/HTTP/1.1_Upgrade_header

Example: JBoss Remoting
GET / HTTP/1.1
Sec-JbossRemoting-Key: f36M+fZYgDQQplAh5sVOYA==
Upgrade: jboss-remoting
Host: scal204:8280
Connection: upgrade

---


=end


          @@tested_paths = []

          threat = <<'EOF'

EOF
          measure = "check if protocol upgrade is intended or needed"

          @info.update(
              :check_name => 'HTTP Upgrade', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => HTTP Protocol,
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
