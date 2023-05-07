# @private
module Watobo#:nodoc: all
  module Modules
    module Passive


      class Api_keys < Watobo::PassiveCheck

        def initialize(project)
            @project = project
          super(project)

          @info.update(
            :check_name => 'Detect API Keys',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Detects API Keys/Credentials which may reveal sensitive information.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )

          @finding.update(
            :threat => 'API may reveal internal information like database passwords.',        # thread of vulnerability, e.g. loss of information
            :class => "API Keys",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

        end

        def do_test(chat)
          begin

            if chat.response.content_type =~ /text/ then

              Watobo::Resources::API_KEYS.each do |type, pattern|
                #   puts "+check pattern #{pat}"
                if  chat.response.join =~ /(#{pattern})/i then
                  #   puts "!!! MATCH !!!"

                  match = $1
                  path = "/" + chat.request.path

                  addFinding(
                  :proof_pattern => "#{Regexp.quote(match)}",
                  :chat => chat,
                  :title => "[#{type}] - #{path}"
                  )
                end
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
