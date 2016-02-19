# @private
module Watobo#:nodoc: all
  module Modules
    module Active
      module Cq5
        #class Dir_indexing < Watobo::Mixin::Session
        class Cq5_default_selectors < Watobo::ActiveCheck

          @info.update(
          :check_name => 'CQ5 Selectors',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => "This module checks for default selectors.",   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "1.0",   # check version
          :check_group => "CQ5"
          )

          @finding.update(
          :threat => 'Selectors can reveal sensitive information about the application, e.g. password hashes (jackrabbit). Also, the query selector enables you to perform XPATH queries on the entire repository, which could slow your system down considerably, or even cause a denial of service if run multiple times',        # thread of vulnerability, e.g. loss of information
          :class => "CQ5: Selectors",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          :rating => VULN_RATING_INFO
          )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            @checked_locations = []
            @selectors = %w( query assets infinity children s7catalog pages feed feedentry tidy sysview docview permissions overlay 1 2 3 4 5 6 7 )
            @extensions = %w( json html csv zip xml )
            # specials are combinations which need one or more parameters to produce a valid result
            @specials = %w( query.json?statement=%2F%2F%2A cqactions.json?path=/&depth=1&authorizableId=* permissions.overlay.json?path=/ )
            
            @mixed = @selectors.map{|s| @extensions.map{|e| s + '.' + e } }.flatten

          end

          def reset()
            @checked_locations = []
          end

          def generateChecks(chat)
             path = chat.request.path
             return false if @checked_locations.include? path
             @checked_locations << path
             
             test_extensions = @extensions
             test_extensions.concat @specials
             test_extensions.concat @mixed
             
             test_extensions.each do |ext|
              checker = proc {
                begin
                  test_request = nil
                  test_response = nil
                  
                  test = chat.copyRequest    
                  
                  # replace file extension only              

                  test.set_file_extension(ext)

                  status, test_request, test_response = fileExists?(test)

                  if status == true and test_response.content_type != chat.response.content_type and test_response.status_code.to_i < 300
                    
                    addFinding(  test_request, test_response,
                      :test_item => "#{test_request.url}",
                      :proof_pattern => "#{test_response.status}",
                      :chat => chat,
                      :title => "[#{ext}]"
                      )

                  end
                  
                  # also test extensions on the path
                  test = chat.copyRequest                 

                  test.replaceFileExt(".#{ext}")

                  status, test_request, test_response = fileExists?(test)

                  if status == true and test_response.content_type != chat.response.content_type and test_response.status_code.to_i < 300
                    
                    addFinding(  test_request, test_response,
                      :test_item => "#{test_request.url}",
                      :proof_pattern => "#{test_response.status}",
                      :chat => chat,
                      :title => "[#{ext}]"
                      )

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
end
