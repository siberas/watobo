# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Xss


        class Xss_script_tag < Watobo::ActiveCheck

          threat = <<'EOF'
Cross-site Scripting (XSS) is an attack technique that involves echoing attacker-supplied code into a user's browser instance. 
A browser instance can be a standard web browser client, or a browser object embedded in a software product such as the browser 
within WinAmp, an RSS reader, or an email client. The code itself is usually written in HTML/JavaScript, but may also extend to 
VBScript, ActiveX, Java, Flash, or any other browser-supported technology.

When an attacker gets a user's browser to execute his/her code, the code will run within the security context (or zone) of the 
hosting web site. With this level of privilege, the code has the ability to read, modify and transmit any sensitive data accessible 
by the browser. A Cross-site Scripted user could have his/her account hijacked (cookie theft), their browser redirected to another 
location, or possibly shown fraudulent content delivered by the web site they are visiting. Cross-site Scripting attacks essentially 
compromise the trust relationship between a user and the web site. Applications utilizing browser object instances which load content 
from the file system may execute code under the local machine zone allowing for system compromise.

Source: http://projects.webappsec.org/Cross-Site+Scripting
EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'Cross Site Scripting via Script-Tag', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_XSS,
              :description => "Check for every parameter if response contains XSS'able content.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Reflected XSS", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
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
                chat.request.parameters.each do |testparm|

                  parm = testparm.copy
                  checker = proc {
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest

                    # build check parameter <prefix></script><suffix>
                    prefix = SecureRandom.hex(3)
                    suffix = SecureRandom.hex(3)
                    inj = prefix + '</script>' + suffix

                    parm.value = inj.dup
                    test.set parm

                    test_request, test_response = doRequest(test)


                    if !!test_response and test_response.has_body? and test_response.body =~ /#{Regexp.quote(inj)}/
                      puts "[#{self.class}] check for injection ..."
                      html = Nokogiri::HTML(test_response.body)
                      script_tags = html.css('script')
                      script_tags.each do |stag|
                        next if stag.content.empty?

                        next unless stag.content =~ /#{prefix}$/i

                        finding_class = "XSS - Reflected [#{parm.location.to_s}]"

                        addFinding(test_request, test_response,
                                   :check_pattern => "#{inj}",
                                   :proof_pattern => "#{inj}",
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
