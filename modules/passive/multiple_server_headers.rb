# @private 
module Watobo #:nodoc: all
  module Modules
    module Passive

      class Multiple_server_headers < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)

          @info.update(
            :check_name => 'Collect Server Headers', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Identify Server Header Information, e.g. Apache 6.x ", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9" # check version
          )

          @finding.update(
            :threat => 'Information about the system maybe revealed', # thread of vulnerability, e.g. loss of information
            :class => "Server Headers", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @server_list = []
        end

        def do_test(chat)
          begin

            chat.response.headers.each do |header|
              if header =~ /^server: (.*)/i then
                server_banner = $1.strip
                # server_banner.gsub!(/^[ ]+/,"")
                pkey = chat.request.site + ':server:' + server_banner
                unless @server_list.include?(pkey)
                  # puts "found different server header"
                  @server_list.push pkey
                  # puts "[#{chat.id}]: #{server_banner}"
                  addFinding(
                    :proof_pattern => "Server: #{server_banner}",
                    :chat => chat,
                    :title => server_banner
                  )
                end

              end

              if header =~ /X-Powered-By: (.*)/i then
                match = $1.strip
                pkey = chat.request.site + ':x-powered-by:' + match
                unless @server_list.include?(pkey)
                  # puts "found different server header"
                  @server_list.push pkey
                  # puts "[#{chat.id}]: #{server_banner}"
                  addFinding(
                    :proof_pattern => "#{match}",
                    :chat => chat,
                    :title => "#{match}",
                    :unique => pkey
                  )
                end

              end

            end

          end
        rescue => bang
          puts "ERROR!! #{Module.nesting[0].name}"
          puts bang
          puts bang.backtrace if $DEBUG

        end
      end

    end
  end
end
