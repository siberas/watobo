# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Detect_json_ld < Watobo::PassiveCheck


        def initialize(project)
          @project = project
          super(project)
          begin
            @info.update(
                :check_name => 'Detect JSON-LD usage', # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "If JSON-LD is used, there might be a chance for special XSS attacks", # description of checkfunction
                :author => "Andreas Schmidt", # author of check
                :version => "1.0" # check version
            )

            measure = <<EOF
This is just an informational hint.
EOF
            @finding.update(
                :threat => 'The usage of json-ld is not a vulnerability. But there might exist a XSS vulnerability, which can be exploitet by injecting a </script> tag.', # thread of vulnerability, e.g. loss of information
                :class => "JSON-LD", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_HINT, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
                :rating => VULN_RATING_INFO,
                :measure => measure
            )

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def do_test(chat)
# check for Bearer Authentication Scheme
# Authorization: Bearer e...
          begin
            if chat.response.content_type =~ /html/i and chat.response.has_body?
              html = Nokogiri::HTML(chat.response.body)
              script_tags = html.css('script')
              jld_tags = script_tags.select { |st| st['type'].to_s =~ /ld.json/i }

              if jld_tags.length > 0
                addFinding(
                    #:check_pattern => "ld.json",
                    :proof_pattern => "ld.json",
                    :title => "[JSON-LD] - #{chat.request.path}",
                    :chat => chat,
                    :details => jld_tags.first.to_s
                )
              end
            end

          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            if $DEBUG
              puts bang.backtrace
              #  binding.pry
            end
          end
        end
      end

    end
  end
end

