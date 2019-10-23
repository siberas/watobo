# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Xml
        class Xml_xxe < Watobo::ActiveCheck
          # This module checks if DTD is accepted
          # The idea is to use regular parameters and convert them to entity
          # if the result is the same, chances are good that XXE attacks will work
          #
          # Links:
          # http://www.w3.org/TR/2004/REC-xml-20040204/#sec-external-ent

          # Exploitation notes:
          # https://www.christian-schneider.net/GenericXxeDetection.html
          # <!ENTITY % three SYSTEM "file:///etc/passwd">
          # <!ENTITY % two "<!ENTITY % four SYSTEM 'file:///%three;'>">

          @info.update(
              :check_name => 'XML-XXE', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => "XML",
              :description => "XML eXternal Entity (XXE).", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          threat = "https://www.owasp.org/index.php/Testing_for_XML_Injection_(OWASP-DV-008)"

          measure = "Disable external entities."

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "External Entities", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)

          end

          def generateChecks(chat)
            begin
               if (chat.request.content_type =~ /xml/) and chat.request.has_body?
               # first we do a request with an
                base = chat.copyRequest
                base_request, base_response = doRequest(base)

                create_entity_packets(chat.request.body).each do |packet|
                  checker = proc {
                    begin
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      test.setData packet.to_s
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
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
          end

          private

          def create_entity_packets(xml_string)
            xml_packets = []

            xmlbase = Nokogiri::XML(xml_string)
            xmlbase.traverse do |node|
              begin
                node.content = 'XXE' if node.text.strip.empty?
                #next if node.parent.namespace.nil?
                unless node.text.strip.empty?
                  xml = Nokogiri::XML(xml_string)
                  xml.create_internal_subset("#{node.parent.name}", nil, nil)
                  node_name = ""
                  if node.parent.respond_to?(:namespace)
                    node_name << "#{node.parent.namespace.prefix}:" if node.parent.namespace.respond_to? :prefix
                  end
                  node_name << "#{node.parent.name}"
                  add_entity(xml, "#{node_name}", "#{node.parent.name}", "#{node.text}")
                  xml_packets << xml


                end
              rescue => bang
                puts bang
              end
            end
            xml_packets
          end

          def add_entity(xml, node_name, entity_name, value)
            xml.create_entity(entity_name, Nokogiri::XML::EntityDecl::INTERNAL_GENERAL, nil, nil, value)
            entity = Nokogiri::XML::EntityReference.new xml, entity_name
            nodeset = xml.xpath("//#{node_name}")
            nodeset.first.send(:native_content=, entity.to_s) unless nodeset.empty?
          end

        end
        # --> eo namespace    
      end
    end
  end
end