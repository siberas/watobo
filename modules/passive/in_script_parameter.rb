require 'cgi'
# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class In_script_parameter < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Parameters in Script',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Checks if parameter values are used within script-tags.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Parameter value may be exploitable for XSS.',        # thread of vulnerability, e.g. loss of information
          :class => "Script-Parameters",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
        end
        
        def showError(chat, message)
          puts "!!! Error in module #{Module.nesting[0].name}"  
          puts "Chat: [#{chat.id}]"
          puts "URL: #{chat.request.url}"
          puts "-- Error --"
          puts message
        end
        
        def do_test(chat)
          begin
            minlen = 3
            return true unless chat.response.content_type =~ /(text|script)/
            return true unless chat.response.has_body?
            
            parm_list = chat.request.parameters(:data, :url)
            return true if parm_list.empty?
            #body = chat.response.body.unpack("C*").pack("C*")
            body = chat.response.body_encoded
            
            doc = Nokogiri::HTML(body)
            scripts = doc.css('script')
            
            parm_list.each do |parm|
              next if parm.value.nil?
              next if parm.value.empty?
              next if parm.value.length <= minlen
              pv = parm.value
              s = chat.request.content_type =~ /(json|xml)/ ? pv : CGI.unescape(pv).unpack("C*").pack("C*")
                            
              pattern = Regexp.quote( s )
              scripts.each do |script|
              if script.text.unpack("C*").pack("C*") =~ /#{pattern}/i then
               # puts "* Found: Parameter within script"
                addFinding(
                           :check_pattern => "#{parm.value}", 
                           :proof_pattern => "#{parm.value}",
                           :chat=>chat,
                           :title =>"[#{parm.value}] - #{chat.request.path}"
                )
              end
                
              end
            end
          rescue => bang
            # raise
            
            showError(chat, bang)
            puts bang
            puts "-- trace --"
            puts bang.backtrace
            
          end
        end
        
      end
    end
  end
end
