# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Dotnet
        
        #class Dir_indexing < Watobo::Mixin::Session
        class Dotnet_files < Watobo::ActiveCheck
          @@tested_directories = Hash.new
          
           @info.update(
                         :check_name => '.NET Files',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "This module checks your application for well known files, e.g. trace.axd.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0",   # check version
            :check_group => ".NET"
            )
            
             @finding.update(
                            :threat => 'Information Disclosure.',        # thread of vulnerability, e.g. loss of information
            :class => ".NET: Well-Known Files",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
             :rating => VULN_RATING_INFO 
            )
            
          def initialize(project, prefs={})
            super(project, prefs)
            
            @wnfs = []
            @wnfs << { :name => "Trace.axd", :pattern => "Trace\.axd.clear=1" }
            @wnfs << { :name => "elmah.axd", :pattern => "Error log for" }
            
            
          end
          
          def reset()
            @@tested_directories.clear
          end
          
          def generateChecks(chat)
            
            begin
              path = chat.request.dir
              if !@@tested_directories.has_key?(path) then
                @@tested_directories[path] = true
                @wnfs.each do |wnf|
                checker = proc {
                  begin
                      test_request = nil
                      test_response = nil
                     
                      test = chat.copyRequest
                 
                      test.replaceFileExt(wnf[:name])
                       status, test_request, test_response = fileExists?(test)
                 
                
                if status == true and test_response.has_body?
                  if test_response.body =~ /#{wnf[:pattern]}/
                    addFinding(  test_request, test_response,
                      :test_item => "#{wnf[:name]}",
                      :proof_pattern => "#{wnf[:pattern]}",
                      :check_pattern => "#{Regexp.quote(wnf[:name])}",
                      :chat => chat,
                      :threat => "depends on the file ;)",
                      :title => "[#{wnf[:name]}]"
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
              end
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
