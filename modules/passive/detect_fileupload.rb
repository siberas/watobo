# @private 
module Watobo#:nodoc: all
  module Modules
    module Passive
      class Detect_fileupload < Watobo::PassiveCheck
        def initialize(project)
          @project = project
          super(project)

          @info.update(
          :check_name => 'Detect File Upload Functionality',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "Detects file upload functions which may be exploited to upload malicious file contents.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )

          @finding.update(
          :threat => 'File upload functions sometimes can be exploited to upload malicious code. This can lead to server- or client-side code excecution.',        # thread of vulnerability, e.g. loss of information
          :class => "File Uploads",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @pattern_list = []
          @pattern_list << '<input [^>]*type=.file.'

        end

        def do_test(chat)
          begin
            return if chat.response.nil? or chat.response.body.nil?
            if chat.response.content_type =~ /text/
                          
              @pattern_list.each do |pat|
              #puts "+check pattern #{pat}"
               # if pat.match(chat.response.body) # =~ /(#{pat})/i then
                if chat.response.body_encoded =~ /(#{pat})/i then
                #   puts "!!! MATCH (FILE UPLOAD)!!!"
                match = $1
                #   puts match
                addFinding(
                :check_pattern => "#{pat}",
                :proof_pattern => "#{match}",
                :title => "#{chat.request.path_ext}",
                :chat => chat
                )

                end
              end
            else
            # puts chat.response.content_type
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
