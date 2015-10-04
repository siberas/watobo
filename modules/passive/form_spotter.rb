# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Form_spotter < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)
          
          @info.update(
                       :check_name => 'Form Spotter',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all HTML-Forms",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Lists all HTML-Forms.',        # thread of vulnerability, e.g. loss of information
          :class => "Forms",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "Check if all forms are checked for vulnerabilities." 
          )
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return true unless chat.response.content_type =~ /(text|script)/
            return true if chat.response.body.nil?
            
            doc = Nokogiri::HTML(chat.response.body)
            doc.css('form').each do |f|
              action = f["action"] 
              next if action.nil?
              title = action.strip.empty? ? "[none]" : "#{action}"
            #  puts "!FOUND FORM #{action}"
            
              # create fingerprint to reduce double entries
              fp = title
              fp << chat.request.site
              
              addFinding(  
                         :proof_pattern => "<form[^>]*#{Regexp.quote(action)}[^>]*>", 
              :title => title,
              :chat => chat,
              :fid => Digest::MD5.hexdigest(fp) 
              )  

            end
          rescue => bang
            #  raise
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
