# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Uri_schemes


        class Scheme_injection < Watobo::ActiveCheck

          threat = <<'EOF'
URI Scheme injection for possible parameter parsing. A controlled DNS is required to see dns requests.
EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'URI Scheme Injection', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "URI Schemes are used as paremeter input to see if application does an DNS request.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "URI Parsing", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)


            @envelop = "watobo"
            @env_count = 0
            @evasions = ["%0a", "%00"]
            @uri_schemes = %w( http https ldap git ftp java php )
            @escape_chars = ['\\']
            @additional_parms = []

            def reset
              @additional_parms = []
              @env_count = 0
            end


          end


          def generateChecks(chat)
            begin
              #

              @parm_list = chat.request.parameters(:data, :url, :json)
              @parm_list.concat @additional_parms
              @parm_list.each do |parm|
                #log_console( "#{parm.location} - #{parm.name} = #{parm.value}")

                checks = []
                @uri_schemes.each do |scheme|
                  %w( php htm html zip jsp doc pdf).each do |fext|
                    @env_count += 1

                    check_id = "watobo_#{scheme}_#{@env_count}"
                    checks << [scheme.dup, "#{scheme}://#{check_id}.#{Watobo::Conf::Scanner.dns_sensor}.#{fext}", check_id]
                  end
                end
                checker = proc {
                  results = {}
                  rating = 0
                  test_request = nil
                  test_response = nil

                  checks.each do |scheme, check, check_id|

                    # accept only one (escape) char between check_id and check string
                    proof = "#{check_id}([^#{Regexp.quote(check)}]?(#{Regexp.quote(check)}){1})"
                    next if results.has_key? scheme
                    test = chat.copyRequest

                    parm.value = CGI.escape(check)
                    test.set parm

                    test_request, test_response = doRequest(test)

                    puts test_request
                    puts '#############################'


                  end

                  [test_request, test_response]
                }
                yield checker

              end

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
