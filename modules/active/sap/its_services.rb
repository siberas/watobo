require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Sap
        
        
        class Its_services < Watobo::ActiveCheck
          
          @info.update(
                         :check_name => 'SAP ITS: Default Services',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks SAP ITS System for enabled default services.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9",   # check version
            :check_group => AC_GROUP_SAP
            )
            
            @finding.update(
                            :threat => 'Information Disclosure (and maybe more)',        # thread of vulnerability, e.g. loss of information
            :class => "SAP ITS: Default Services",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
          
          def initialize(project, prefs={})
          
            super(project, prefs)
            
            
            @its_services = [ 
                  "admin", 
                  "webgui", 
                  "systeminfo",
            ]
          end
          
          def generateChecks(chat)
            
            begin
              
              if chat.request.url.to_s =~ /\/wgate\/(\w*\/!?)/ then
                service_name = $1
                @its_services.each do |service|
                  checker = proc{
                    test_request = nil
                    test_response = nil
                    c_service = "#{service.dup}"
                    c_srv_name = "#{service_name}"
                    test = chat.copyRequest
                    test.first.gsub!(c_srv_name, "#{c_service}/!")                
                    
                    test_request,test_response = doRequest(test, :default => true)
                    
                    
                    if test_response.status =~ /200/i then
                      #test_chat = Chat.new(test,test_response,chat.id)
                      addFinding( test_request,test_response,
                      :test_item => chat.request.url,
                                 :check_pattern => "#{c_service}",
                      :proof_pattern => "#{test_response.status}",
                      :chat => chat,
                      :title => c_service
                      )
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                end            
              end
            rescue => bang
              puts bang
              puts "ERROR!! #{Module.nesting[0].name}"
            end
          end
          
        end
        # --> eo namespace    
      end
    end
  end
end
