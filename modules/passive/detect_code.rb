# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Detect_code < Watobo::PassiveCheck
       
        def initialize(project)
            @project = project
          super(project)
          
          @info.update(
            :check_name => 'Detect Code Snippets',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Detects code snippets which may reveal sensitive information.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
          @finding.update(
            :threat => 'Code snippets may reveal internal information like database passwords.',        # thread of vulnerability, e.g. loss of information
            :class => "Code Snippets",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
          )
          
         
          @pattern_list = []
          @pattern_list << ['<\?php', "PHP" ]
          @pattern_list << [ '<!--[^>]*select ', "COMMENT" ]
          @pattern_list << [ '\/\*[^(\*\/)]*select ', "COMMENT" ]
          @pattern_list << [ '\/\/[^(\*\/\n)]*select ', "COMMENT" ]
          @pattern_list << [ 'sample code', "COMMENT" ]
              @pattern_list << [ '<%[^<%]*%>', "ASP" ]
          
          
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/ then
            
              @pattern_list.each do |pat, type|
                #   puts "+check pattern #{pat}"
                if  chat.response.body_encoded =~ /(#{pat})/i then
                  #   puts "!!! MATCH !!!"
                  
                  match = $1
                  path = "/" + chat.request.path
                  addFinding(  
                  :proof_pattern => "#{Regexp.quote(match)}", 
                  :chat => chat,
                  :title => "[#{type}] - #{path}"
                  )
                end
            end
            end
          rescue => bang
            #raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end
      
    end
  end
end
