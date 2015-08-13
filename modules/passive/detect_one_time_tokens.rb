# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Detect_one_time_tokens < Watobo::PassiveCheck
   
        
        def initialize(project)
            @project = project
          super(project)
          begin
           @info.update(
            :check_name => 'Detect One-Time-Tokens',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Detects parameters which are used as One-Time-Tokens to prevent CSRF-Attacks.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'Informational',        # thread of vulnerability, e.g. loss of information
            :class => "One-Time-Tokens",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
          
          @pattern_list = []
          @pattern_list << "csrf"
              @pattern_list << "token"       
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
        end
        
        def do_test(chat)
          begin
            parm_names = chat.request.parm_names
            
            parm_names.each do |parm|
            @pattern_list.each do |pat|
              #puts "+check pattern #{pat}"
              if  parm =~ /(#{pat})/i then
               match = $1
             #   puts match
                addFinding(  
                :check_pattern => "#{pat}",
                :proof_pattern => "#{match}", 
                :title => "[#{parm}] - #{chat.request.path}", 
                :chat => chat
                )
               
             end
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
