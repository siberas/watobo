# @private
module Watobo #:nodoc: all
  module Modules
    module Passive

      class Odata < Watobo::PassiveCheck
=begin
        {
           "@odata.context": "https://some.doma.in/dpp/api/odata/$metadata",
           "value": [
             {
               "name": "FeedbackOData",
               "kind": "EntitySet",
               "url": "FeedbackOData"


=end

        def initialize(project)
          @project = project
          super(project)

          @info.update(
            :check_name => 'ODATA API Detection', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Detect Microsoft ODATA Protocol Interface", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9" # check version
          )

          @finding.update(
            :threat => 'ODATA may leak database internals.', # thread of vulnerability, e.g. loss of information
            :class => "ODATA API", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_TECH, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :measure => "Hack the planet.",
          )

          @odata_patterns = []
          @odata_patterns << '@odata\.context\b'
          @odata_patterns.map!{|p| Regexp.compile(p) }.freeze

        end

        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            #   puts "body" + chat.response.body.join
            return if chat.response.nil?

            if chat.response.has_body?
              body = chat.response.body.to_s
              body.strip!
              # first we check if body might be json
              if body.match?(/^\{.*\}$/)
                @odata_patterns.each do |p|
                  if body.match?(p)
                    addFinding(
                      :proof_pattern => "#{p}",
                      :chat => chat,
                      :title => "[#{chat.request.file}] - #{chat.request.path}"
                    )
                    break
                  end
                end
              end

            end

          rescue => bang
            # raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

    end
  end
end
