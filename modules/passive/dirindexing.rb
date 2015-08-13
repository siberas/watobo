
# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Dirindexing < Watobo::PassiveCheck
        
        def initialize(project)
          @project = project
          super(project)
          @info.update(
                       :check_name => 'Directory Indexing',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects if directory indexing is not disabled.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'May reveal sensitive information..',        # thread of vulnerability, e.g. loss of information
          :class => "Directory Indexing",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_LOW 
          )
          
          @tested_directories = []
          
          @pattern_list = []
          @pattern_list << 'Parent Directory</a>'
          @pattern_list << 'Directory Listing for'
          @pattern_list << '<title>.*Folder Listing.*<\/title>'
          @pattern_list << '<title>.*Index of /.*</title>'
          
          @pattern_list << '<table summary="Directory Listing" '
          @pattern_list << 'Browsing directory'
          @pattern_list << 'To Parent Directory'
        end
        
        def do_test(chat)
          begin
            @pattern_list.each do |pat|
              next unless chat.response.has_body?
               body = chat.response.body_encoded
               if body =~ /(#{pat})/i then
                 match = $1
                 addFinding(  
                           :proof_pattern => "#{match}",
                           :chat => chat,
                           :title => "/#{chat.request.path}"
                )
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
