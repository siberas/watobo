
# @private
module Watobo#:nodoc: all
  module Modules
    module Passive


      class OracleIplanetHeaders < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)
          @info.update(
              :check_name => 'Oracle iPlanet Headers',    # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "checks for headers which are used by Oracle iPlanet Webserver",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0"   # check version
          )

          @finding.update(
              :threat => 'May reveal sensitive information..',        # thread of vulnerability, e.g. loss of information
              :class => "iPlanet Header",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @tested_directories = []

          @pattern_list = [ 'Proxy-agent' ]


        end

        def do_test(chat)
          begin

            @pattern_list.each do |pat|
              chat.response.headers(pat) do |header|
                next unless chat.response.has_body?
                match, val = header.split(":")
                addFinding(
                    :proof_pattern => "#{header}",
                    :chat => chat,
                    :title => "#{val}"
                )

              end
            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end
        end
      end

    end
  end
end
