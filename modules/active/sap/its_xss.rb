require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Sap
        
        
        class Its_xss < Watobo::ActiveCheck
          
          @info.update(
                         :check_name => 'SAP ITS: XSS',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks for generic XSS flaws in SAP ITS Systems.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9",   # check version
            :check_group => AC_GROUP_SAP
            )
            
            @finding.update(
                            :threat => 'Information Disclosure (and maybe more)',        # thread of vulnerability, e.g. loss of information
            :class => "SAP ITS: XSS",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
          
          def initialize(project, prefs={})
            @project = project
            super(project, prefs)
            
          end
          
          def generateChecks(chat)
            
            #
            #  Check GET-Parameters
            #
            begin
              
              if chat.request.url.to_s =~ /!$/ then 
                checker = proc{
                test = chat.copyRequest
                new_p = "~urlmime"
                new_v = "\"><script>alert('watobo')</script><img src=\""
                test.add_get_parm(new_p,new_v)
                
                test_request,test_response = doRequest(test,:default => true)
                                
                if test_response.join =~ /watobo/i then
                  #test_chat = Chat.new(test,test_response,chat.id)
                  addFinding(test_request,test_response,
                  :test_item => chat.request.url.to_s,
                         :check_pattern => "#{new_p}",
                         :proof_pattern => "#{new_v}",
                         :chat => chat,
                         :title => new_p
                          )
                end
                [ test_request, test_response ]
                }
                yield checker
              end            
              
            rescue => bang
              puts bang
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
           
              
            end
          end
        end
        
        # --> eo namespace    
      end
    end
  end
end
