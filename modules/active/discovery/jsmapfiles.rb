# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Discovery


        class Jsmapfiles < Watobo::ActiveCheck

          @info.update(
              :check_name => 'JavaScript Map Files', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks for javascript map files", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => 'Temporary- or backup files may contain sensitive information, e.g. source-code or username/password.', # thread of vulnerability, e.g. loss of information
              :class => "JS Map File", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_INFO # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name=nil, prefs={})
            #  @project = project
            super(session_name, prefs)

          end

          def reset()

          end

          def generateChecks(chat)

            begin
              file = chat.request.file

              return nil unless file =~ /\.js$/ and chat.response.content_type =~ /javascript/i

              checker = proc {
                test_request = nil
                test_response = nil

                new_file = file + '.map'
                test_request = chat.copyRequest

                test_request.replaceFileExt(new_file)

                status, test_request, test_response = fileExists?(test_request, :default => true)

                if status == true then
                  addFinding(test_request, test_response,
                             :check_pattern => "#{new_file}",
                             :test_item => file,
                             :proof_pattern => "#{test_response.status}",
                             :chat => chat,
                             :title => "#{new_file}"
                  #:debug => true
                  )
                end
                [test_request, test_response]
              }
              yield checker

            rescue => bang

              puts "ERROR!! #{Module.nesting[0].name} "
              puts "chatid: #{chat.id}"
              puts bang
              puts

            end
          end
        end
      end
    end
  end
end
