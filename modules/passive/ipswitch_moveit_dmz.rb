require 'cgi'

# @private
module Watobo#:nodoc: all
  module Modules
    module Passive


      class Ipswitch_moveit_dmz < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)

          @info.update(
              :check_name => 'IPSWITCH MOVEit DMZ Detection',    # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks for special HTTP header values used by IPSWITCH MOVEit DMZ",   # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0"   # check version
          )

          @finding.update(
              :threat => 'MOVEit installation may contain vulnerabilities.',        # thread of vulnerability, e.g. loss of information
              :class => "MOVEit DMZ Installation",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

          @patterns = [ 'X\-siLock\-', 'siLockLongTermInstID', 'DesignModeTest']

        end

        def showError(chatid, message)
          puts "!!! Error #{Module.nesting[0].name}"
          puts "Chat: [#{chatid}]"
          puts message
        end

        def do_test(chat)
          begin
            return false if chat.response.nil?


            @patterns.each do |pattern|
              unless chat.response.headers(pattern).empty?
                addFinding(
                    #:check_pattern => "#{pattern[:pattern]}",
                    :proof_pattern => "#{pattern}",
                    :chat=>chat,
                    :title =>"[ #{pattern} ] - #{chat.request.path}",
                )

              end
            end
          rescue => bang
            # raise
            puts bang
            puts bang.backtrace
            showError(chat.id, bang)
          end
        end

      end
    end
  end
end
