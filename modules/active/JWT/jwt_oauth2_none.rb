# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Jwt

        class Jwt_oauth2_none < Watobo::ActiveCheck
          @@tested_directories = Hash.new

          threat =<<'EOF'
Privilege Escalation
EOF

#
          details =<<'EOD'

EOD


          measure = 'Only accept secure algorithms.'

          @info.update(
              :check_name => 'OAuth2 Anonymous JWT', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => 'JWT',
              :description => 'Checks if anonymous token (without signature) is supported by the application.', # description of checkfunction
              :author => 'Andreas Schmidt', # author of check
              :version => '1.0' # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "JWT - None", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :measure => measure,
              :details => details
          )

          def initialize(project, prefs={})
            super(project, prefs)

            def reset

            end


          end


          def generateChecks(chat)
            begin
              # Check for JWT Bearer Header, e.g.
              # Authorization: Bearer asdfasdfasdf.alksjdflkjsdlfjkweoriuwoejosjfoijowemrjosjajjojpj.Xm7q8hzlXlooWPyZPayq ...
              bearer = chat.request.headers(' Bearer ')[0]
              return true if bearer.nil?

              jwt = bearer.match(/Bearer (.*)/)[1]
              jh, jp, js = jwt.split('.')
              jh = JSON.parse(Base64.decode64(jh))
              jp = JSON.parse(Base64.decode64(jp))

              # remove 'alg' from original header
              jh.delete 'alg'

              # TODO: improve check to also compare responses which don't have a body
              body_orig = chat.response.body.to_s
              return true if body_orig.empty?

              checker = proc {
                request = nil
                response = nil
                test_request = chat.copyRequest

                # create new token with original header fields - except 'alg'
                token = JWT.encode jp, nil, 'none', jh

                new_auth_header = "Bearer #{token}"

                test_request.set_header 'Authorization', new_auth_header

                request, response = doRequest(test_request)

                if response.body.to_s.strip == body_orig.strip

                  addFinding(request, response,
                             :check_pattern => token,
                             :proof_pattern => body_orig.strip,
                             #:test_item => '',
                             :chat => chat,
                             :title => "[#{request.file}]"
                  )
                end

                [request, response]
              }
              yield checker

            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
            end
          end

        end

      end
    end
  end
end
