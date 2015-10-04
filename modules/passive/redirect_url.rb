# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Redirect_url < Watobo::PassiveCheck
        
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Detect Redirect Parameters',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks parameters for suspicious names like 'url' or 'goto'.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Redirect functionalities can be exploited by an attacker redirect a user to an malicious site (Drive By Attacks).',        # thread of vulnerability, e.g. loss of information
          :class => "Redirect Parameters",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
          @suspicious_names = ['url', 'extern', 'goto', 'redirect', 'jump']
        end
        
        def do_test(chat)
          begin
            chat.request.get_parm_names.each do |parm|
              @suspicious_names.each do |sn|
               # puts "#{parm} : #{sn}"
                if parm =~ /(#{sn})/i  then
                  
                  addFinding(
                              :check_pattern => "#{parm}=", 
                              :proof_pattern =>"#{parm}=",
                              :chat => chat,
                              :title => parm  
                              )
                end
              end
            end
            
            chat.request.post_parm_names.each do |parm|              
              @suspicious_names.each do |sn|
                if parm =~ /(#{sn})/i  then
                  addFinding(
                              :check_pattern => "#{parm}=", 
                              :proof_pattern =>"#{parm}=",
                              :chat => chat,
                              :title => parm
                                          )
                end
              end
            end       
          rescue => bang
            raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end
        end
        
      end
    end
  end
end
