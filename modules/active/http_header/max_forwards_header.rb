=begin
http://www.wisec.it/sectou.php?id=4698ebdc59d15

$ curl -i -H "Negotiate: watobo" http://192.168.70.134/index
HTTP/1.1 406 Not Acceptable
Date: Fri, 24 Jan 2014 08:46:35 GMT
Server: Apache/2.2.22 (Debian)
Alternates: {"index.bak" 1 {type application/x-trash} {length 0}}, {"index.html" 1 {type text/html} {length 177}}, {"index.tgz" 1 {type application/x-gzip} {length 0}}
Vary: negotiate,accept,Accept-Encoding
TCN: list
Content-Length: 568
Content-Type: text/html; charset=iso-8859-1

<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>406 Not Acceptable</title>
</head><body>
<h1>Not Acceptable</h1>
<p>An appropriate representation of the requested resource /index could not be found on this server.</p>
Available variants:
<ul>
<li><a href="index.bak">index.bak</a> , type application/x-trash</li>
<li><a href="index.html">index.html</a> , type text/html</li>
<li><a href="index.tgz">index.tgz</a> , type application/x-gzip</li>
</ul>
<hr>
<address>Apache/2.2.22 (Debian) Server at 192.168.70.134 Port 80</address>
</body></html>

=end

# @private
module Watobo#:nodoc: all
  module Modules
    module Active
      module Http_header


        class Max_forwards_header < Watobo::ActiveCheck

          @@tested_paths = []

          details =<<EOD
This check inserts the HTTP header Max-Forwards with a zero value. In general this header is only used in conjunction with the TRACE or OPTIONS method. But sometimes also regular methods will get answered.
The response might include sensitive information about the underlying system. As well it might be interesting for further attacks like connecting to internal hosts by modifying the host header.
EOD

          @info.update(
              :check_name => 'Max-Forwards HTTP Header',    # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks if request runs through a proxy server.",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :check_group => AC_GROUP_GENERIC,
              :version => "1.0"   # check version
          )

          @finding.update(
              :threat => 'The use of the max-forwards header might reveal sensitive information of the infrastructure.',        # thread of vulnerability, e.g. loss of information
              :class => "Max-Forwards Header",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :rating => VULN_RATING_INFO,
              :measure => "Filter Max-Forwards HTTP header or supress responses with sensitive information.",
              :details => details,
              :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name=nil, prefs={})
            #  @project = project
            super(session_name, prefs)
            @@response_hashes = []
            @@tested_paths = []

           end

          def reset()
            @@tested_paths.clear
            @@response_hashes.clear
          end


          def generateChecks(chat)

            begin

              checker = proc{
                  test_request = nil
                  test_response = nil
                  test_request = chat.copyRequest

                  test_request.set_header("Max-Forwards","0")

                  t_request, t_response = doRequest(test_request, :default => true)

                  unless Watobo::Utils.compare_responses(t_response, chat.response)

                    addFinding( t_request, t_response,
                                :check_pattern => "Max-Forwards",
                                :chat => chat,
                                :title => "Max-Forwards - #{t_request.path}"
                    )
                  end
                  [ t_request, t_response ]
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
