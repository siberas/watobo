# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Xml
        class Xml_doctype_dns < Watobo::ActiveCheck
          # XML Attacks
          # https://www.vsecurity.com/download/papers/XMLDTDEntityAttacks.pdf
          #

          @info.update(
              :check_name => 'XML-Doctype-DNS', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => "XML",
              :description => "Checks if Doctype declaration gets resolved. A DNS sensor is required!", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          threat = "https://www.owasp.org/index.php/Testing_for_XML_Injection_(OWASP-DV-008)"

          measure = "Disable Doctype declarations."

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Doctype declarations", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_MEDIUM,
              :measure => measure
          )


          def initialize(project, prefs = {})
            super(project, prefs)

            @schemas = %w( http https ftp mail jar file netdoc mailto gopher doc verbatim systemresource php data glob phar zip rar ogg expect ssh2.exec ssh2.shell ssh2.tunnel ssh2.sftp ssh2.scp )
          end

          def generateChecks(chat)
            begin
              return nil unless (chat.request.content_type =~ /xml/ and chat.request.has_body?)
              #puts "Body:\n#{chat.request.body}"
              # first we do a request with an
              base = chat.copyRequest
              base_request, base_response = doRequest(base)


              @schemas.each do |schema|
                checker = proc {
                  begin
                    test_request = nil
                    test_response = nil

                    new_doc, pattern = add_doctype(schema, chat.request.body)
                    test = chat.copyRequest
                    test.setData new_doc.to_s

                    # puts pattern
                    # TODO: implement collab check

                    test_request, test_response = doRequest(test)

                    #puts test_response.status

                    if test_response.has_body? and base_response.has_body?

                      if test_response.body == base_response.body
                        addFinding(test_request, test_response,
                                   :test_item => "ENTITY",
                                   :check_pattern => "ENTITY",
                                   :chat => chat,
                                   :title => "[#{chat.request.path}] - ENTITY",
                                   :debug => true
                        )
                      elsif test_response.status_code =~ /2\d\d/
                        addFinding(test_request, test_response,
                                   :test_item => "ENTITY",
                                   :check_pattern => "ENTITY",
                                   :chat => chat,
                                   :title => "[#{chat.request.path}] - ENTITY",
                                   :debug => true,
                                   :rating => VULN_RATING_MEDIUM
                        )
                      end
                    end
                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                  end
                  [test_request, test_response]
                }
                yield checker

              end

            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end

          end

          private

          def add_doctype(schema, xml_string)
            xml_packets = []

            xmlbase = Nokogiri::XML(xml_string)
            # first we remove existing doctypes
            xmlbase.document.internal_subset.remove unless xmlbase.document.internal_subset.nil?

            # create pattern for collab server
            pattern = schema + '_' + Time.now.to_f.to_s.gsub(/.*\./, '')

            xmlbase.document.create_internal_subset('Document', 'watobo', "#{schema}://#{pattern}.#{Watobo::Conf::Scanner.dns_sensor}")


            [xmlbase, pattern]
          end


        end
        # --> eo namespace
      end
    end
  end
end