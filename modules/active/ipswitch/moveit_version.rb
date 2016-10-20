# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Ipswitch
        #class Dir_indexing < Watobo::Mixin::Session
        class Moveit_version < Watobo::ActiveCheck

          @info.update(
              :check_name => 'MoveIt DMZ Version', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "This module checks the version of a MoveIt DMZ Version.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0", # check version
              :check_group => "IPSwitch MoveIT"
          )

          @finding.update(
              :threat => 'The exact version number can be used to prepare a special attack', # thread of vulnerability, e.g. loss of information
              :class => "MoveIT DMZ: Version", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_INFO
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

                test = chat.copyRequest

                moveit_path = dir + 'MOVEitISAPI/MOVEitISAPI.dll?action=capa'

                test.set_path moveit_path

                test_request, test_response = doRequest(test)

                version = nil

                test_response.headers('X-MOVEitISAPI-Version') do |header|
                  version = header.match(/X-MOVEitISAPI-Version: (.*)/)[1]
                end

                unless version.nil?

                  addFinding(test_request, test_response,
                             :test_item => "#{test_request.url}",
                             :proof_pattern => "X-MOVEitISAPI-Version: #{version}",
                             :chat => chat,
                             :title => "[#{version}]"
                  )

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
