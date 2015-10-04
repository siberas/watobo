# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Hidden_fields < Watobo::PassiveCheck
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Hidden Fields',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all hidden fields",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0"   # check version
          )
          
          @finding.update(
                          :threat => 'Hidden field parameters sometimes are accepted as input variables.',        # thread of vulnerability, e.g. loss of information
          :class => "Hidden Fields",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "N/A" 
          )
         

        end
        
        def do_test(chat)
          begin
            
            if chat.response.content_type =~ /(text|script)/ and chat.response.status !~ /404/ and chat.response.has_body? then
              doc = Nokogiri::HTML(chat.response.body)
              doc.xpath('//input[@type="hidden"]').each do |i|
                pp = "<input[^<]+name=.#{i[:name]}[^<]+/?>"
                #pp = Regexp.quote(tag)
                # nokogiri only uses double quotes
                #pp.gsub!(/['"]/,".")
                # also nokogiro removes trailing /
                #pp.gsub!(/>$/, "/?>")
                addFinding(  
                           :proof_pattern => pp, 
                           :title => "#{i[:name]}",
                           :chat => chat
                          )  
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end
    end
  end
end
