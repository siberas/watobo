# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Disclosure_domino < Watobo::PassiveCheck
        
        def initialize(project)
           @project = project
          super(project)
          
          @info.update(
            :check_name => 'Domino DB name disclosure.',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Identifies Domino DB names.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
            
          @finding.update(
            :threat => 'Unintended disclosure of Domino DB name can lead to data breach.',        # thread of vulnerability, e.g. loss of information
            :class => "Domino DB Names",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
        
          @pattern = '([a-zA-Z\/\-0-9\.:]+\.nsf)'
          @dbs = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/ then
              chat.response.body_encoded.split("\n").each do |line|
                if line =~ /#{@pattern}/ then
                  match = $1
                  if not @dbs.include?(match) then
                    @dbs.push match
                    addFinding( 
                                :proof_pattern => "#{match}",
                                :chat => chat,
                                :title => match
                                )
                  end
                end                
              end
            end
          rescue => bang
          #  raise
            puts "ERROR!! #{self.class}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end
      
    end
  end
end
