
# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Cookie_xss < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
            :check_name => 'Cookie XSS',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "If cookies will be used in the content body, they can be misused for XSS-Attacks.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'A cookie value has been found in the body of the HTML page. This may be exploited for XSS attacks.',        # thread of vulnerability, e.g. loss of information
            :class => "Cookie Security",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/
              chat.request.cookies do |cookie|
                 cval = Regexp.quote(cookie.value)
                 if chat.response.body_encoded =~ /#{cval}/ and cval.length > 5 then
                   addFinding(:proof_pattern => "#{cval}", 
                      :check_pattern => "#{cval}", 
                      :chat => chat, 
                      :title => "[#{cname}] - #{chat.request.path}")
                   break
                 end
               end
             end
             return true
           rescue => bang
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
