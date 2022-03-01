# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Detect_java_serialization < Watobo::PassiveCheck


        def initialize(project)
          @project = project
          super(project)
          begin
            @info.update(
                :check_name => 'Detect serialized java objects.', # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "Detects serialized java objects in parameters and header fields.", # description of checkfunction
                :author => "Andreas Schmidt", # author of check
                :version => "1.0" # check version
            )

            @finding.update(
                :threat => 'Deserialization Attack', # thread of vulnerability, e.g. loss of information
                :class => "Serialized Java Object", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
                :rating => VULN_RATING_CRITICAL
            )


            @pattern = 'rO0'

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def do_test(chat)
          begin
            # we only care about serialization if response is valid
            return unless chat.response.status_code =~ /^2\d\d/
            parms = chat.request.parameters

            parms.each do |parm|
              puts parm.value.to_s
              if parm.value.to_s =~ /(#{@pattern})/i then
                match = $1
                #   puts match
                addFinding(
                    :check_pattern => "#{@pattern}",
                    :proof_pattern => "#{match}",
                    :title => "[#{parm.name}] - #{chat.request.path}",
                    :chat => chat
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
