require 'cgi'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Xss_dom < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'DOM XSS',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks for suspcious javascript functions which manipulate the Browsers DOM and may be misused for Cross-Site-Scripting-Attacks.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Parameter value may be exploitable for XSS.',        # thread of vulnerability, e.g. loss of information
          :class => "DOM XSS",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
            @dom_functions = [ 'document\.write',
                               'document\.url',
                               'document\.location',
                               #'document\.execCommand',
                               'document\.attachEvent',
                               'eval\(',
                               'window\.open',
                               'window\.location',
                               #'document\.create',
                               "\.innerHTML",
                               "\.outerHTML"]
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
            
            @dom_functions.each do |pattern|
             # body = chat.response.body.unpack("C*").pack("C*")
             body = chat.response.body_encoded
              if body =~ /(#{pattern})/i then
               match = $1.strip
               match.gsub!(/^[\.\(\)]+/,'')
               match.gsub!(/[\.\(\)]+$/,'')
                addFinding(
                           :check_pattern => "#{pattern}", 
                :proof_pattern => "#{pattern}",
                :chat=>chat,
                # :title =>"[#{pattern}] - #{chat.request.path}",
                :title =>"[ #{match} ]"
                #:class => "DOM XSS"            
                )
                
              end
            end
          rescue => bang
            # raise
            showError(chat.id, bang)
          end
        end
        
      end
    end
  end
end
