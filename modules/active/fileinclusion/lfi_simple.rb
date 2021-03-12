require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo #:nodoc: all
  module Modules
    module Active
      module Fileinclusion


        class Lfi_simple < Watobo::ActiveCheck
          @info.update(
              :check_name => 'Local File Inclusion', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks for parameters, which can lead to local file inclusion.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :check_group => AC_GROUP_FILE_INCLUSION,
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => 'Code Execution or Information Leakage', # thread of vulnerability, e.g. loss of information
              :class => "Local File Inclusion", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          def initialize(project, prefs = {})
            super(project, prefs)


            @include_checks = [
                ["etc/passwd", 'root:[^:]+:\w+:\w+'],
                ["etc/passwd%00", 'root:[^:]+:\w+:\w+'],
                ["boot.ini", Regexp.quote('[boot loader]')],
                ["boot.ini%00", Regexp.quote('[boot loader]')]
            ]

            @updirs = [0, 5, 10, 15, 20]

          end

          def generateChecks(chat)
            begin
              @updirs.each do |up|
                @include_checks.each do |file, pattern|
                  @parm_list = chat.request.parameters
                  @parm_list.each do |p|
                    param = p.copy
                    checker = proc {
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      check = "../" * up + file
                      param.value = check

                      test.set param
                      test_request, test_response = doRequest(test)


                      #  test_chat = Chat.new(test, test_response, chat.id)
                      if test_response.join =~ /(#{pattern})/ # if default db found, check for content
                        match = $1
                        addFinding(test_request, test_response,
                                   :check_pattern => "#{file}",
                                   :test_item => param.value,
                                   :proof_pattern => "#{match}",
                                   :chat => chat,
                                   :rating => VULN_RATING_HIGH,
                                   :title => "[#{parm}] - #{test_request.file}"
                        )
                      end
                      [test_request, test_response]
                    }
                    yield checker
                  end
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
        # --> eo namespace
      end
    end
  end
end
