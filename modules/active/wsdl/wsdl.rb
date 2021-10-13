# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Wsdl
=begin
body = <<EOF
        <?xml version="1.0" encoding="UTF-8" standalone="no"?>
            <wsdl:definitions xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
        xmlns:tns="http://www.cleverbuilder.com/BookService/"
        xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        name="BookService"
        targetNamespace="http://www.cleverbuilder.com/BookService/">
        <wsdl:documentation>Definition for a web service called BookService,
                                                                which can be used to add or retrieve books from a collection.
            </wsdl:documentation>

        <!--
            The `types` element defines the data types (XML elements)
        that are used by the web service.
            -->
                                 <wsdl:types>
            <xsd:schema targetNamespace="http://www.cleverbuilder.com/BookService/">
            <xsd:element name="Book">
            <xsd:complexType>
            <xsd:sequence>
            <xsd:element name="ID" type="xsd:string" minOccurs="0"/>
        <xsd:element name="Title" type="xsd:string"/>
        <xsd:element name="Author" type="xsd:string"/>
        </xsd:sequence>
        </xsd:complexType>
            </xsd:element>
      <xsd:element name="Books">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element ref="tns:Book" minOccurs="0" maxOccurs="unbounded"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>

      <xsd:element name="GetBook">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element name="ID" type="xsd:string"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>
      <xsd:element name="GetBookResponse">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element ref="tns:Book" minOccurs="0" maxOccurs="1"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>

      <xsd:element name="AddBook">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element ref="tns:Book" minOccurs="1" maxOccurs="1"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>
      <xsd:element name="AddBookResponse">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element ref="tns:Book" minOccurs="0" maxOccurs="1"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>
      <xsd:element name="GetAllBooks">
        <xsd:complexType/>
            </xsd:element>
      <xsd:element name="GetAllBooksResponse">
        <xsd:complexType>
          <xsd:sequence>
            <xsd:element ref="tns:Book" minOccurs="0" maxOccurs="unbounded"/>
            </xsd:sequence>
        </xsd:complexType>
            </xsd:element>
    </xsd:schema>
            </wsdl:types>


  <!--
      A wsdl `message` element is used to define a message
      exchanged between a web service, consisting of zero
      or more `part`s.
   -->

  <wsdl:message name="GetBookRequest">
    <wsdl:part element="tns:GetBook" name="parameters"/>
            </wsdl:message>
  <wsdl:message name="GetBookResponse">
    <wsdl:part element="tns:GetBookResponse" name="parameters"/>
            </wsdl:message>
  <wsdl:message name="AddBookRequest">
    <wsdl:part name="parameters" element="tns:AddBook"></wsdl:part>
            </wsdl:message>
  <wsdl:message name="AddBookResponse">
    <wsdl:part name="parameters" element="tns:AddBookResponse"></wsdl:part>
            </wsdl:message>
  <wsdl:message name="GetAllBooksRequest">
    <wsdl:part name="parameters" element="tns:GetAllBooks"></wsdl:part>
            </wsdl:message>
  <wsdl:message name="GetAllBooksResponse">
    <wsdl:part name="parameters" element="tns:GetAllBooksResponse"></wsdl:part>
            </wsdl:message>

  <!--
      A WSDL `portType` is used to combine multiple `message`s
      (e.g. input, output) into a single operation.

      Here we define three synchronous (input/output) operations
        and the `message`s that must be used for each.
            -->
            <wsdl:portType name="BookService">
            <wsdl:operation name="GetBook">
            <wsdl:input message="tns:GetBookRequest"/>
            <wsdl:output message="tns:GetBookResponse"/>
            </wsdl:operation>
    <wsdl:operation name="AddBook">
      <wsdl:input message="tns:AddBookRequest"></wsdl:input>
            <wsdl:output message="tns:AddBookResponse"></wsdl:output>
    </wsdl:operation>
            <wsdl:operation name="GetAllBooks">
            <wsdl:input message="tns:GetAllBooksRequest"></wsdl:input>
      <wsdl:output message="tns:GetAllBooksResponse"></wsdl:output>
            </wsdl:operation>
  </wsdl:portType>

            <!--
                The `binding` element defines exactly how each
        `operation` will take place over the network.
            In this case, we are using SOAP.
                -->
                                       <wsdl:binding name="BookServiceSOAP" type="tns:BookService">
        <soap:binding style="document"
        transport="http://schemas.xmlsoap.org/soap/http"/>
        <wsdl:operation name="GetBook">
            <soap:operation
        soapAction="http://www.cleverbuilder.com/BookService/GetBook"/>
        <wsdl:input>
            <soap:body use="literal"/>
            </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
            </wsdl:output>
    </wsdl:operation>
            <wsdl:operation name="AddBook">
            <soap:operation
        soapAction="http://www.cleverbuilder.com/BookService/AddBook"/>
        <wsdl:input>
            <soap:body use="literal"/>
            </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
            </wsdl:output>
    </wsdl:operation>
            <wsdl:operation name="GetAllBooks">
            <soap:operation
        soapAction="http://www.cleverbuilder.com/BookService/GetAllBooks"/>
        <wsdl:input>
            <soap:body use="literal"/>
            </wsdl:input>
      <wsdl:output>
        <soap:body use="literal"/>
            </wsdl:output>
    </wsdl:operation>
            </wsdl:binding>

  <!--
      The `service` element finally says where the service
      can be accessed from - in other words, its endpoint.
   -->
  <wsdl:service name="BookService">
    <wsdl:port binding="tns:BookServiceSOAP" name="BookServiceSOAP">
      <soap:address location="http://www.example.org/BookService"/>
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
EOF
=end

        class Wsdl < Watobo::ActiveCheck

          @info.update(
              :check_name => 'WSDL Files', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "Checks for WSDL files", # description of checkfunction
              :check_group => "WSDL",
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => 'WSDL definition may leak information of hidden functions.', # thread of vulnerability, e.g. loss of information
              :class => "WSDL File", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )


          def initialize(session_name = nil, prefs = {})
            #  @project = project
            super(session_name, prefs)

            @wsdl_checks = []
            @wsdl_checks << '_wsdl'
            @wsdl_checks << 'wsdl'
            @wsdl_checks << 'WSDL'

          end

          def reset()

          end

          def generateChecks(chat)

            begin
              file = chat.request.file
              checks = []
              @wsdl_checks.each do |wsdl|
                checks << "#{file}?#{wsdl}"
                checks << "#{file};#{wsdl}"
                checks << "#{file}.svc?#{wsdl}"
                checks << "#{file}.svc;#{wsdl}"
                checks << "#{file.gsub(/\..*$/, '')}.svc?#{wsdl}"
                checks << "#{file.gsub(/\..*$/, '')}.svc;#{wsdl}"
                checks << "svc/#{file}?#{wsdl}"
                checks << "svc/#{file};#{wsdl}"
                checks << "svc/#{file}.svc?#{wsdl}"
                checks << "svc/#{file}.svc;#{wsdl}"
                checks << "svc/#{file.gsub(/\..*$/, '')}.svc?#{wsdl}"
                checks << "svc/#{file.gsub(/\..*$/, '')}.svc;#{wsdl}"
              end

              checks.each do |check|
                checker = proc {
                  test_request = nil
                  test_response = nil


                  test_request = chat.copyRequest

                  test_request.replaceFileExt(check)

                  status, test_request, test_response = fileExists?(test_request, :default => true)

                  if status == true && test_response.has_body?
                    if test_response.body.to_s =~ /<\?xml/i
                      begin
                        wsdl_xml = Nokogiri::XML test_response.body.to_s
                        if wsdl_xml.namespaces["xmlns:wsdl"]
                          addFinding(test_request, test_response,
                                     :check_pattern => "#{check}",
                                     :test_item => check,
                                     :proof_pattern => "#{test_response.status}",
                                     :chat => chat,
                                     :title => "[ #{test_response.status_code} ] - #{check}"
                          #:debug => true
                          )
                        end
                      rescue => bang
                        puts bang if $VERBOSE || $DEBUG
                        puts bang.backtrace if $DEBUG
                      end
                    end
                  end
                  [test_request, test_response]
                }
                yield checker
              end
            rescue => bang

              puts "ERROR!! #{Module.nesting[0].name} "
              puts "chatid: #{chat.id}"
              puts bang
              puts

            end
          end
        end
      end
    end
  end
end
