require 'digest/md5'
require 'digest/sha1'

# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Sqlinjection


        class Sqli_time_based < Watobo::ActiveCheck
          @info.update(
              :check_name => 'Time-based SQL Injection 2', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_SQL,
              :description => "Checking each parameter for SQL-Injection flaws using timing techniques.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          threat = <<'EOF'
SQL Injection is an attack technique used to exploit applications that construct SQL statements from user-supplied input. 
When successful, the attacker is able to change the logic of SQL statements executed against the database.
Structured Query Language (SQL) is a specialized programming language for sending queries to databases. 
The SQL programming language is both an ANSI and an ISO standard, though many database products supporting SQL do so with 
proprietary extensions to the standard language. Applications often use user-supplied data to create SQL statements. 
If an application fails to properly construct SQL statements it is possible for an attacker to alter the statement structure 
and execute unplanned and potentially hostile commands. When such commands are executed, they do so under the context of the user 
specified by the application executing the statement. This capability allows attackers to gain control of all database resources 
accessible by that user, up to and including the ability to execute commands on the hosting system.

Source: http://projects.webappsec.org/SQL-Injection
EOF

          measure = "All user input must be escaped and/or filtered thoroughly before the sql statement is put together. Additionally prepared statements should be used."

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "SQL-Injection", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :measure => measure
          )


          def initialize(project, prefs = {})
            super(project, prefs)

          end

          def generateChecks(chat)
            sql_timing_commands = [
                'and sleep(SLEEP_TIME)',
                'and 1 in (select BENCHMARK(20000000,MD5(CHAR(97))))',
                'and waitfor delay \'0:0:SLEEP_TIME\''
            ]

            sqli_vectors = [
                '',
                '\'',
                '\'))',
                '\')))',
                ')',
                '))',
                ')))'
            ]

            sql_terminators = [
                '', '--', ';--'
            ]

            sqli_patterns = []
            sqli_vectors.each do |v|
              sql_timing_commands.each do |stc|
                sql_terminators.each do |sts|
                  sqli_patterns << "#{v} #{stc}#{sts}"
                end
              end
            end

            sqli_patterns.each do |sql|
              # get ALL parameters
              chat.request.parameters() do |parm|


                checker = proc {
                  test_request = nil
                  test_response = nil


                  # first get multiple response times
                  rtimes = []

                  timing_response = nil

                  vulnerable = false

                  4.times do
                    test = chat.copyRequest
                    start = Time.now().to_i
                    timing_request, timing_response = doRequest(test, :default => true)
                    stop = Time.now().to_i
                    rtimes << (stop - start)

                  end
                  # now calculate the average time
                  average_t = rtimes.inject(:+) / rtimes.length
                  max_t = rtimes.max > 5 ? rtimes.max : 5
                  # puts "Analyzing timing behaviour ..."
                  # rtimes.each do |t|
                  #   puts t.to_s
                  # end
                  # puts "Average Response Time: #{average_t}s (max #{max_t}s)"

                  #     time_to_sleep = 4 * max_t
                  time_to_sleep = max_t
                  #timeout_t = time_to_sleep + average_t
                  timeout_t = 2 * time_to_sleep

                  test_value = ""

                  sqli_start = sqli_stop = 0


                  timeout_counter = 0
                  output = ""
                  break if vulnerable
                  begin
                    sqli_start = Time.now().to_i
                    Timeout.timeout(timeout_t) do
                      test = chat.copyRequest
                      # also need to check if altered parm will change response
                      test_value = CGI.escape("#{parm.value}#{sql.gsub(/SLEEP_TIME/, time_to_sleep.to_s)}")

                      parm.value = test_value
                      test.set parm

                      test_request, test_response = doRequest(test, :default => true)
                      sqli_stop = Time.now().to_i
                    end
                  rescue Timeout::Error

                    sqli_stop = Time.now().to_i
                    output << "Hit Timeout after #{sqli_start - sqli_stop} seconds\n"


                  rescue => bang
                    puts bang
                    puts bang.backtrace
                  end


                  duration = sqli_stop - sqli_start
                  #  puts duration
                  if (duration >= time_to_sleep)
                    puts "Found time-based SQLi in parameter #{parm} !!!"
                    puts "after #{duration}s / time-to-sleep #{time_to_sleep}s)"
                    test_request.extend Watobo::Mixin::Parser::Url unless test_request.respond_to? :path
                    path = "/" + test_request.path

                    output << "SleepTime: #{time_to_sleep}\nQuery Duration: #{duration}s"

                    addFinding(test_request, test_response,
                               :check_pattern => "#{test_value}",
                               :chat => chat,
                               :title => "[#{parm.name}] - #{path}",
                               :proof_pattern => "",
                               :test_item => parm.name,
                               :class => "SQL-Injection (Time-based)",
                               :output => output
                    )

                  end


                  [test_request, test_response]
                }
                yield checker
              end
            end
          end
        end

        # --> eo namespace
      end
    end
  end
end
