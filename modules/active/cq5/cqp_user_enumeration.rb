# @private
module Watobo#:nodoc: all
  module Modules
    module Active
      module Cq5
        #class Dir_indexing < Watobo::Mixin::Session
        class Cqp_user_enumeration < Watobo::ActiveCheck

          @info.update(
          :check_name => 'CQ5 CQP User Enumeration',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "This module checks if CQ JSON extension is aktive and enumerates all usernames.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0",   # check version
          :check_group => "CQ5"
          )

          @finding.update(
          :threat => 'Information Disclosure.',        # thread of vulnerability, e.g. loss of information
          :class => "CQ5: Users",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_INFO
          )
          def initialize(project, prefs={})
            super(project, prefs)

          end

          def reset()
            @checked_locations = []
          end

          def generateChecks(chat)

            path = chat.request.path
            return false if @checked_locations.include? path
            @checked_locations << path
            #
            # via JSON Extension

            checker = proc {
              begin
                test_request = nil
                test_response = nil

                test = chat.copyRequest

                test.set_file_extension('.json')

                status, test_request, test_response = fileExists?(test)

                if status == true and test_response.has_body?
                  if test_response.content_type =~ /json/
                    j = JSON.parse test_response.body.to_s
                    username = j['jcr:createdBy']
                    # puts "\nCQ5 User: #{username}"
                    addFinding(  test_request, test_response,
                      :test_item => "#{test_request.url}",
                      :proof_pattern => "jcr:createdBy.*#{username}",
                      :chat => chat,
                      :threat => "Usernames may help an attacker to perform authorization attacks, e.g. brute-force attacks.",
                      :title => "[#{username}]"
                      )
                  end

                end
              rescue => bang
                puts bang
                puts bang.backtrace if $DEBUG
              end
              [ test_request, test_response ]

            }
            yield checker

            #
            # via XML Extension
            
            checker = proc {
              begin
                test_request = nil
                test_response = nil

                test = chat.copyRequest

                test.set_file_extension('.xml')

                status, test_request, test_response = fileExists?(test)

                if status == true and test_response.has_body?
                  if test_response.content_type =~ /xml/
                    xml = Nokogiri::XML(test_response.body.to_s)
                    xml.traverse do |node|
                      next unless node.respond_to? :attributes
                      node.attributes.each do |attr|
                        if attr[0] =~ /By$/i
                          username = attr[1]  
                          addFinding(  test_request, test_response,
                      :test_item => "#{test_request.url}",
                      :proof_pattern => "#{attr[0]}.*#{username}",
                      :chat => chat,
                      :threat => "Usernames may help an attacker to perform authorization attacks, e.g. brute-force attacks.",
                      :title => "[#{username}]"
                      )
                        end
                      end
                    end

                  end

                end
              rescue => bang
                puts bang
                puts bang.backtrace if $DEBUG
              end
              [ test_request, test_response ]

            }
            yield checker

          end
        end
      end
    end
  end
end
