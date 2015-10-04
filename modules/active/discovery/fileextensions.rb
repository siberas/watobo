# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Discovery
        
        
        class Fileextensions < Watobo::ActiveCheck
           
           @info.update(
                         :check_name => 'FileExtensions',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Checks for temporary- or backup-files",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            @finding.update(
                            :threat => 'Temporary- or backup files may contain sensitive information, e.g. source-code or username/password.',        # thread of vulnerability, e.g. loss of information
            :class => "File Extension",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :rating => VULN_RATING_HIGH,
            :type => FINDING_TYPE_VULN         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
          
          def initialize(session_name=nil, prefs={})
          #  @project = project
            super(session_name, prefs)
            
           
            
            
            #  @tested_directories = Hash.new
            @fext = %w( php asp aspx jsp cfm shtm htm html shml )
            @prefixes = [ "", "~", "_"]
            @suffixes = [ "tmp", "bak", "tgz", "tar.gz", "tar", "gz", "zip", "bz2", "old"]
          end
          
          def reset()
           
          end
          
          def generateChecks(chat)
            
            begin
              file = chat.request.file
              #e = dummy.split('?').first
              
              if file != "" and file =~ /\.(#{@fext.join("|")})$/ then
             
                @prefixes.each do |pref|
                  @suffixes.each do |suf|
                    
                    #sleep(1)
                    checker = proc{
                      test_request = nil
                      test_response = nil
                      new_file = pref + file.gsub(/\.\w{1,4}$/, ".#{suf}")
                    #  puts new_file
                      # !!! ATTENTION !!!
                      # MAKE COPY BEFORE MODIFIYING REQUEST 
                      test_request = chat.copyRequest
                      
                      test_request.replaceFileExt(new_file)
                      # result_request, result_response = doRequest(test_request, :default => true)
                      #   puts test_request.first
                      
                      status, test_request, test_response = fileExists?(test_request, :default => true)
                      # puts new_e + " : " + test_response.status
                      if status == true then                     
                        puts "GOTCHA - #{self.class}!!!\n+ #{test_request.first}\n"
                        #test_chat = Chat.new(test_request, test_response, chat.id)
                        addFinding( test_request, test_response,
                                   :check_pattern => "#{new_file}",
                                   :test_item => file,
                        :proof_pattern => "#{test_response.status}",
                        :chat => chat,
                        :title => "#{new_file}"
                        #:debug => true
                        )                        
                      end
                      [ test_request, test_response ] 
                    }
                    yield checker
                    
                    checker = proc{
                      test_request = nil
                      test_response = nil
                      new_file = pref + file + ".#{suf}"
                      
                      # !!! ATTENTION !!!
                      # MAKE COPY BEFORE MODIFIYING REQUEST 
                      test_request = chat.copyRequest
                      
                      test_request.replaceFileExt(new_file)
                      # result_request, result_response = doRequest(test_request, :default => true)
                      
                      
                      status, test_request, test_response = fileExists?(test_request, :default => true)
                      # puts new_e + " : " + test_response.status
                      
                      if status == true then                     
                        #  puts "\n+ #{test_request.first}\n"
                       # test_chat = Chat.new(test_request, test_response, chat.id)
                        addFinding( test_request, test_response,
                                   :check_pattern => "#{new_file}",
                                   :test_item => file,
                        :proof_pattern => "#{test_response.status}",
                        :chat => chat,
                        :title => "#{new_file}"
                        #:debug => true
                        )                        
                      end
                      [ test_request, test_response ] 
                    }
                    yield checker
                    
                  end    
                end      
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
