# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Gwt_Rpc < Watobo::PassiveCheck


        def initialize(project)
          @project = project
          super(project)
          begin
            @info.update(
                :check_name => 'GWT-RPC Content-Type', # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "This module checks for GWT-RPC content.", # description of checkfunction
                :author => "Andreas Schmidt", # author of check
                :version => "1.0" # check version
            )

            measure = <<EOF
GWT-RPC can be used for deserialization attacks if proper configuration is missing.
EOF
            @finding.update(
                :threat => 'Possible Java Deserialization', # thread of vulnerability, e.g. loss of information
                :class => "GWT-RPC Communication", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_HINT, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
                :rating => VULN_RATING_INFO,
                :measure => measure
            )

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def do_test(chat)
# check for Bearer Authentication Scheme
# Authorization: Bearer e...
          begin
            if chat.request.content_type =~ /gwt-rpc/i

              addFinding(
                  :check_pattern => "#{chat.request.content_type}",
                  #:proof_pattern => "#{auth_match}",
                  :title => "[RPC-GWT] - #{chat.request.path}",
                  :chat => chat,
                  :details => chat.request.content_type
              )
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

