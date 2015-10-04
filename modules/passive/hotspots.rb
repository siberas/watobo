# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      
      
      class Hotspots < Watobo::PassiveCheck
        def initialize(project)
         @project = project
          super(project)
          
          @info.update(
                        :check_name => 'Active Content References',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects all references to active content pages, e.g. php, asp.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'References to active content pages have been found. Sometimes old and/or vulnerable functions are revealed. With this information you can also estimate if all parts of the application are covered.',        # thread of vulnerability, e.g. loss of information
          :class => "Hotspots",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_INFO,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :measure => "Check if these references are only pointing to \"good\" functions." 
          )
         
          
        
          @pattern_list = %w( php asp aspx jsp cgi )
		  
          @known_functions = []
        end
        
        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return false if chat.response.nil?
            return false unless chat.response.has_body?
            if chat.response.content_type =~ /(text|script)/ and chat.response.status !~ /404/ then
             
              #body = chat.response.body.unpack("C*").pack("C*")
              body = chat.response.body_encoded
              return false if body.nil?
              
              body.split(/\n/).each do |line|
                    @pattern_list.each do |ext|
                      if line =~ /([\w%\/\\\.:-]*\.#{ext})[^\w]/ then
                        match = $1
                        hotspot = Watobo::Utils::URL.create_url(chat, match)
                        if not @known_functions.include?(match) then
                          addFinding(  
                                       :proof_pattern => match, 
                                       :title => hotspot,
                                       :chat => chat,
                                       :fid => Digest::MD5.hexdigest("#{self}#{hotspot}")
                          )  
                          @known_functions.push match
                        end
                      end                  
                end
              end
            end
          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace
          end
        end
      end
      
    end
  end
end
