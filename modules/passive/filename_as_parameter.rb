# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Filename_as_parameter  < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Detect Filename Parameters',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects parameters which sounds like 'filename', e.g. filename, fname.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'If filename parameters are not proper handled by the application an attacker may excecute malicious files or reveal sensitive information.',        # thread of vulnerability, e.g. loss of information
          :class => "Filename Parameter",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
        
          @possible_parm_names=%w[ (.*fname.*) (.*file.*) ]
          @findings = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            chat.request.parameters(:url, :wwwform, :xml, :json) do |parm|

                @possible_parm_names.each do |pattern|
                  
                  if parm.name =~ /#{pattern}/i
                    match = $1
                    if not @findings.include?(parm.name)
                      @findings.push parm.name
                      addFinding(
                                 :check_pattern => match,
                                 :chat=>chat
                      )
                    end
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
