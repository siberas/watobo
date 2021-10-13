# @private
module Watobo#:nodoc: all
  module Modules
    module Passive


      class Authorization_leak < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)

          @info.update(
              :check_name => 'Detect Authorization Header',    # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Detects Authorization header in server response",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9"   # check version
          )

          @finding.update(
              :threat => 'Authorization headers may leak username password information.',        # thread of vulnerability, e.g. loss of information
              :class => "Authorization Header",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_HIGH,
          :measure => "Remove Authorization header from server response.",
          )

        end

        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil?
           
            chat.response.headers.each do |header|

                if  header.strip =~ /^Authorization: (.*) (.*)$/i then
                  auth_type = $1
                  match = $2
                  path = "/" + chat.request.path
                  addFinding(
                      :proof_pattern => "#{Regexp.quote(header.strip)}",
                      :chat => chat,
                      :title => "[Authorization #{auth_type}] - #{path}"
                  )
                end

            end
          rescue => bang
            #raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

    end
  end
end
