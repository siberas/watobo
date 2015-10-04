# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Xss
        
        
        class Xss_simple < Watobo::ActiveCheck
          
          threat =<<'EOF'
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
                         :check_name => 'Simple Cross Site Scripting Checks',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_XSS,
            :description => "Check for every parameter if response contains XSS'able content.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "Reflected XSS",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_HIGH,
            :measure => measure
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            
            
            @xss_checks=[ 
            ["<script>watobo</script>", "<script>watobo</script>"],
            ["%3Cscript%3Ewatobo%3C/script%3E", "<script>watobo</script>"],
            ["%0a<script>watobo</script>", "<script>watobo</script>"],              # prepend %0A can circumvent checks ... seen in the wild
            ["%0a%3Cscript%3Ewatobo%3C/script%3E", "<script>watobo</script>"],   # prepend %0A can circumvent checks ... seen in the wild
            ["<watobo", "<watobo"],
            ["%00<watobo", "<watobo"],
            ["%3Cwatobo%3E", "<watobo>"], 
            ]
            
            
          end
          
          
          def generateChecks(chat)    
            #
            #  Check GET-Parameters
            #
            begin
              
              
              urlParmNames(chat).each do |parm|
               # puts parm
                # puts "#{Module.nesting[0].name}: run check on chat-id (#{chat.id}) with parm (#{parm})"
                @xss_checks.each do |check, pattern|
                  checker = proc {
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest
                    test.replace_get_parm(parm, check)
                    test_request,test_response = doRequest(test)
                                       
                    if not test_response then
                      puts "got no respons :("
                    elsif test_response.join =~ /(#{pattern})/i
                      match = $1
                    #    puts "found xss (get)"
                   #   test_chat = Chat.new(test,test_response,chat.id)
                      
                    #  resource = "/" + test_request.resource
                      
                      addFinding(test_request, test_response,
                                 :check_pattern => "#{check}", 
                      :proof_pattern => "#{match}", 
                      :test_item => parm,
                      :class => "Reflected XSS [GET]", 
                      :chat => chat,
                      :title => "[#{parm}] - #{test_request.path}"
                      )
                    end
                    #@project.new_finding(:short_name=>"#{parm}", :check=>"#{check}", :proof=>"#{pattern}", :kategory=>"XSS-Post", :type=>"Vuln", :chat=>test_chat, :rating=>"High")
                    [ test_request, test_response ]
                  }
                  yield checker
                end
              end
              
              
              
              #
              #  Check POST-Parameters
              #
              
              postParmNames(chat).each do |parm|
                #puts "#{chat.id}: run check on post parm #{parm}"
                @xss_checks.each do |check, pattern|
                  
                  
                  checker = proc {
                    
                    test = chat.copyRequest
                    # modify the test request
                    test.replace_post_parm(parm, check)
                    test_request,test_response = doRequest(test)
                    
                    match = nil
                    if test_response.join =~ /(#{pattern})/i
                      match = $1
                   #   puts "Reflected XSS [POST] - #{parm}"
                    #  test_chat = Chat.new(test, test_response, chat.id)
                     # resource = "/" + test_request.resource
                      addFinding(test_request, test_response,
                      :test_item => parm,
                                 :check_pattern => "#{check}", 
                      :proof_pattern => "#{match}", 
                      :class => "Reflected XSS [POST]", 
                      :chat => chat,
                      :title => "[#{parm}] - #{test_request.path}"
                      )
                    end
                    # don't use 'return' here
                    [ test_request, test_response ]
                  }
                  yield checker
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
end
