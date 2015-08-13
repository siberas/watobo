# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Autocomplete < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Password AutoComplete',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks Password Fields For AutoCompletion",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Password values may be stored on the local filesystem.',        # thread of vulnerability, e.g. loss of information
          :class => "Password Autocompletion",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
           :rating => VULN_RATING_LOW,
          :measure => "The form field should have an attribute autocomplete=\"off\"" 
          )
        end
        
        def do_test(chat)
          begin
                       
           if chat.response.respond_to? :input_fields     
             chat.response.input_fields do |f|
            
              ac = f.autocomplete.nil? ? "" : f.autocomplete
              
              if f.type =~ /password/i and ( ac =~ /off/i or ac.empty? )          
              addFinding(  
                         :proof_pattern => "input[^>]*type=[^>=]*password.*>{1}", 
              :title => "#{chat.request.file}",
              :chat => chat
              )  
              end
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return false
        end
      end
      
    end
  end
end
