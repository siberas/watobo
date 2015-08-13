# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Dotnet
        #class Dir_indexing < Watobo::Mixin::Session
        class Custom_errors < Watobo::ActiveCheck
          @@tested_directories = Hash.new
          
           @info.update(
            :check_name => '.NET Custom Error',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "This module checks if custom errors messages are used and Stack-Tracing is enabled.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0",   # check version
            :check_group => ".NET"
            )

            @finding.update(
            :threat => 'Information Disclosure. Internal error messages are exposed to end users.',        # thread of vulnerability, e.g. loss of information
            :class => ".NET: Custom Errors",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_INFO
            )
            
          def initialize(project, prefs={})
            super(project, prefs)

           

          end

          def generateChecks(chat)

            begin

              if chat.request.url.to_s =~ /\.aspx/ then

                checker = proc {
                  begin
                    test_request = nil
                    test_response = nil

                    test = chat.copyRequest
                    test.set_method("POST")
                    
                    test.set_content_type("application/x-www-form-urlencoded")
                    test.set_content_length("0")
                    test.setData "__VIEWSTATE=watobo"
                    
                    status, test_request, test_response = fileExists?(test)
                    
                    if test_response.has_body? and test_response.body =~ /Server Error in/

                      puts ".NET Custom Error >> #{test.url.to_s}"

                      addFinding(  test_request, test_response,
                             :test_item => "__VIEWSTATE",
                             :proof_pattern => Regexp.quote("Server Error in"),
                  :check_pattern => Regexp.quote("__VIEWSTATE"),
                  :chat => chat,
                  :threat => "Information Disclosure: Error messages may disclose potentially sensitive information about the internal implementation of the website.",
                  :title => "[Server Error]"
                  )

                      trace_pattern = "customErrors mode=.*RemoteOnly"
                      if test_response.body =~ /#{trace_pattern}/i
                        #puts "STACK-TRACE!!!"
                        addFinding(  test_request, test_response,
                             :test_item => "__VIEWSTATE",
                             :proof_pattern => trace_pattern,
                  :check_pattern => Regexp.quote("__VIEWSTATE"),
                  :chat => chat,
                  :threat => "Information Disclosure: A Stack-Trace may disclose potentially sensitive information about the internal implementation of the website.",
                  :title => "[Stack-Trace]",
                  :class => ".NET: Stack-Trace"
                  )

                      end

                    end

                    [ test_request, test_response ]

                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                  end
                  [ nil, nil ]

                }
              yield checker
              end
            rescue => bang
              puts "!error in module #{Module.nesting[0].name}"
              puts bang
            end
          end

        end
      end
    end
  end
end
