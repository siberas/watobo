# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Directories
        
        #class Dir_indexing < Watobo::Mixin::Session
        class Dirwalker < Watobo::ActiveCheck
          @@tested_directories = Hash.new
          
           @info.update(
                         :check_name => 'Directory Walker',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Do request on each directory and run passive checks on result.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0"   # check version
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
           
            
            
          end
          
          def reset()
            @@tested_directories.clear
          end
          
          def generateChecks(chat)
            
            begin
              path = chat.request.dir
              if !@@tested_directories.has_key?(path) then
                @@tested_directories[path] = true
                checker = proc {
                  begin
                      test_request = nil
                      test_response = nil
                      test = chat.copyRequest
                      test.strip_path()
                      test_request, test_response = doRequest(test, :default => true)
                  rescue => bang
                    puts bang
                    puts bang.backtrace if $DEBUG
                  end
                  [ test_request, test_response ]
                  
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
