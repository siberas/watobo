# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Wrong_content_type < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)
          @info.update(
              :check_name => 'Wrong content type', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "checks if http body is of the same type given in the header.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => 'If content type header is html but the body is of another type, chances are high to use this for an XSS attack.', # thread of vulnerability, e.g. loss of information
              :class => "Wrong Content-Type", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @tested_directories = []

        end

        def do_test(chat)
          begin
            ct = chat.response.content_type
            if ct =~ /(html|script)/i
              unless chat.response.body.to_s =~ /html/i

                addFinding(
                    :proof_pattern => "#{ct}",
                    :chat => chat,
                    :title => "#{ct}"
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
