
# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Sap_headers < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          @info.update(
                       :check_name => 'SAP Headers',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "checks for headers which contain 'sap-', e.g. sap-srt_server_info.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'May reveal sensitive information..',        # thread of vulnerability, e.g. loss of information
          :class => "SAP Header",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )
          
          @tested_directories = []
          
          @pattern_list = [ '^sap-' ]
          
         
        end
        
        def do_test(chat)
          begin
            
            @pattern_list.each do |pat|
              chat.response.headers(pat) do |header|
              next unless chat.response.has_body?
                 match = header.split(":")[0]
                 addFinding(  
                           :proof_pattern => "#{header}",
                           :chat => chat,
                           :title => "#{match}"
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
