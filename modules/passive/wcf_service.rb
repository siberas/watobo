# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Wcf_service < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)

          @svc_patterns = []
          @svc_patterns << 'You can do this using the svcutil.exe tool'

          @info.update(
              :check_name => 'WCF Service Detection', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Detect Microsoft WCF Service Definition", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => 'WCF Services may be dangerous.', # thread of vulnerability, e.g. loss of information
              :class => "WCF Service", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_HINT, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :measure => "Hack the planet.",
          )

        end

        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil?

            if chat.response.has_body?
              body = chat.response.body.to_s
              @svc_patterns.each do |p|
                if body =~ /#{Regexp.quote(p)}/i
                  addFinding(
                      :proof_pattern => "#{p}",
                      :chat => chat,
                      :title => "[#{chat.request.file}] - #{chat.request.path}"
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
