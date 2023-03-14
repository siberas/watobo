# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Rspec


        class Test_module < Watobo::ActiveCheck

          @@tested_paths = []

          details = <<EOD
Test module needed only for rspec tests
EOD

          @info.update(
              :check_name => 'Test module for rspec', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "does nothing", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :check_group => 'RSPEC',
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => 'none', # thread of vulnerability, e.g. loss of information
              :class => "None", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :rating => VULN_RATING_INFO,
              :measure => "N/A",
              :details => details,
              :type => FINDING_TYPE_VULN # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name = nil, prefs = {})
            #  @project = project
            super(session_name, prefs)

            #  @tested_directories = Hash.new
            @fext = %w( php asp aspx jsp cfm shtm htm html shml )

          end

          def reset()
            @@tested_paths.clear
          end


          def generateChecks(chat)
            #  nothing to do here

          end
        end
      end
    end
  end
end
