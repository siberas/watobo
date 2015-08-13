# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Disclosure_emails < Watobo::PassiveCheck
        
        def initialize(project)
           @project = project
          super(project)
          
          @info.update(
            :check_name => 'Email Adresses',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Collects email adresses.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'email adresses can be used for social engineering attacks.',        # thread of vulnerability, e.g. loss of information
            :class => "EMail Adresses",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
          valid = '[a-zA-Z\d\.+-]+'
          @pattern = "(#{valid}@#{valid}\\.(#{valid}){2})"
          @mail_list = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return false if chat.response.nil?
            return false unless chat.response.has_body?
            if chat.response.content_type =~ /text/ and not chat.response.content_type =~ /text.csv/ then
              body = chat.response.body_encoded
              body.scan(/#{@pattern}/) { |m|
                  match = m.first
                  unless @mail_list.include?(match) then
                    @mail_list.push match
                    addFinding( 
                                :proof_pattern => "#{match}", 
                                :chat => chat,
                                :title => match
                                )
                  end
              }
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
