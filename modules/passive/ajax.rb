require 'cgi'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Ajax < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Ajax',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Spots Ajax Frameworks like jQuery.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.1"   # check version
          )
          
          @finding.update(
                          :threat => 'Framework may contain vulnerabilities.',        # thread of vulnerability, e.g. loss of information
          :class => "Ajax Framework",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
            @fw_patterns = []
            @fw_patterns << { :name => 'jQuery', :pattern => 'jQuery v([0-9\.]*) .*jquery.(com|org)'}
        end
        
        def showError(chatid, message)
          puts "!!! Error #{Module.nesting[0].name}"  
          puts "Chat: [#{chatid}]"
          puts message
        end
        
        def do_test(chat)
          begin
            return false if chat.response.nil?
            return false unless chat.response.has_body?
            return true unless chat.response.content_type =~ /(text|script)/ 
            
            @fw_patterns.each do |pattern|
              #body = chat.response.body.unpack("C*").pack("C*")
              body = chat.response.body_encoded
              
              if body =~ /#{pattern[:pattern]}/i then
               version = $1.strip
               addFinding(
                           #:check_pattern => "#{pattern[:pattern]}", 
                :proof_pattern => "#{pattern[:pattern]}",
                :chat=>chat,
                :title =>"[ #{pattern[:name]} #{version} ] - #{chat.request.path}",            
                )
                
              end
            end
          rescue => bang
            # raise
            puts bang
            puts bang.backtrace
            showError(chat.id, bang)
          end
        end
        
      end
    end
  end
end
