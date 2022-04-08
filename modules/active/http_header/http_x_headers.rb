# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Http_header


        class Http_x_headers < Watobo::ActiveCheck

          @@tested_paths = []

          details = <<EOD
This check is injecting HTTP headers which are known to be able to manipulate the request flow of Loadbalancers or Reverse-Proxies.
EOD

          @info.update(
              :check_name => 'X-HTTP Header Injection', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks if http routing can be changed.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :check_group => AC_GROUP_GENERIC,
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => 'Packet routing might be manipulated, which could lead to url filter evasion.', # thread of vulnerability, e.g. loss of information
              :class => "X-HTTP-Header", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :rating => VULN_RATING_INFO,
              :measure => "Filter/remove injected headers.",
              :details => details,
              :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name = nil, prefs = {})
            #  @project = project
            super(session_name, prefs)
            @@response_hashes = []
            @@tested_paths = []
            @schemas = %w( https url )
            @inj_headers = %w(
X-Forwarded-For
X-Host
X-Forwarded-Server
X-Forwarded-Host
X-Forwarded-Scheme
X-Original-URL
X-Rewrite-URL
Accept
Accept-Datetime
Accept-Charset
Accept-Encoding
Accept-Language
Alt-Svc
Base-Url
CF-Connecting-IP
Cache-Control
Client-IP
Cluster
Cluster-Client-IP
Connection
Contact
Content-Length
Content-MD5
Content-Type
Cookie
DNT
Date
Destination
Expect
Forwarded
From
Front-End-Https
HTTP_CLIENT_IP
HTTP_FORWARDED
HTTP_FORWARDED_FOR
HTTP_X_FORWARDED
HTTP_X_FORWARDED_FOR
Host
Http-Url
If-Match
If-Modified-Since
If-None-Match
If-Range
If-Unmodified-Since
Link
Location
Max-Forwards
Origin
Pragma
Profile
Proxy
Proxy-Authorization
Proxy-Connection
Proxy-Host
Proxy-Url
Range
Real-IP
Redirect
Referer
Referrer
Refferer
Refferrer
Request-Uri
TE
True-Client-IP
UID
Upgrade
Uri
User-Agent
Via
Warning
X-ATT-DeviceId
X-Arbitrary
X-CSRFToken
X-Client-IP
X-Cluster-Client-IP
X-Correlation-ID
X-Csrf-Token
X-Do-Not-Track
X-Error-Msg
x-error-msg
X-Forward-For
X-Forwarded
X-Forwarded-By
X-Forwarded-For
X-Forwarded-For-IP
X-Forwarded-For-Original
X-Forwarded-Host
X-Forwarded-Proto
X-Forwarded-Server
X-Forwarder-For
X-Host
X-Http-Destinationurl
X-Http-Host-Override
X-Http-Method-Override
X-Original-Remote-Addr
X-Original-Url
X-Originating-IP
X-Proxy-Url
X-ProxyUser-IP
X-Real-IP
X-Remote-Addr
X-Remote-IP
X-Request-ID
X-Requested-With
X-Rewrite-Url
X-True-IP
X-UIDH
X-Wap-Profile
X-XSRF-TOKEN
            )

          end

          def reset()
            @@tested_paths.clear
            @@response_hashes.clear
          end


          def generateChecks(chat)
            @inj_headers.each do |inj_header|
              @schemas.each do |schema|
                checker = proc {
                  begin
                    test_request = nil
                    test_response = nil
                    test_request = chat.copyRequest

                    inj_host = "#{schema}://#{checkid}.#{Watobo::Conf::Scanner.dns_sensor}"
                    test_request.set_header(inj_header, inj_host)

                    t_request, t_response = doRequest(test_request, :default => true)

                    unless Watobo::Utils.compare_responses(t_response, chat.response)

                      addFinding(t_request, t_response,
                                 :check_pattern => inj_header,
                                 :chat => chat,
                                 :title => "#{inj_header} - #{t_request.path}"
                      )
                    end
                  rescue => bang

                    puts "ERROR!! #{Module.nesting[0].name} "
                    puts "chatid: #{chat.id}"
                    puts bang
                    puts

                  end
                  [t_request, t_response]
                }
                yield checker
              end
            end
          end
        end
      end
    end
  end
end
