# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Siebel
        
        class Siebel_apps < Watobo::ActiveCheck
          check_group = File.dirname(File.expand_path(__FILE__)).split("/").last.capitalize!
          @@tested_directories = Hash.new
          
          @info.update(
                         :check_name => 'Siebel Applications',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Enumerate Siebel Applications And Default Files, e.g. base.txt",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0",   # check version
            :check_group =>  check_group
            )
            
            @finding.update(
                            :threat => 'Information',        # thread of vulnerability, e.g. loss of information
            :class => "Siebel: Default Applications",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_INFO         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
          
          def initialize(project, prefs={})
           
            super(project, prefs)
            
            @apps = %w( callcenter cgce cra eCommunicationsWireless eEnergyOilGasChemicals eaf eai eai_anon eauctionswexml eautomotive echannelaf echannelcg echannelcme eclinical ecommunications econsumer econsumerpharma econsumersector ecustomer ecustomercme edealer edealerscw eenergy eevents ehospitality eloyalty emarketing emedia emedical ememb epharma epharmace eprofessionalpharma epublicsector eretail erm ermadmin esales esalescme eservice esitesclinical etraining finesales fins finsconsole finscustomer finsebanking finsebrokerage finsechannel finseenenrollment finssalespam htim htimpim loyalty loyaltyscw marketing medicalce pimportal pmmanager prmmanager prmportal pseservice sales salesce service servicece siasalesce siaservicece sismarketing smc wpeserv wppm wpsales wpserv )
            @langs = %w( cat chs cht csy dan deu ell enu esn euq fin fra frc heb hun ita jpn kor nld nor plk pse psl ptb ptg rus shl sky slv sve tha trk )
            
            
          end
          
           def reset()
            @@tested_directories.clear

          end
          
          
          def generateChecks(chat)
            
            begin
              path = chat.request.dir
             # puts "!!!!#{self}: #{path}"
              unless @@tested_directories.has_key?(path)
                @@tested_directories[path] = true
                
                @apps.each do |app|
                  @langs.each do |lang|
                    
                    
                  checker = proc{
                    begin
                    app_dir = "#{app}_#{lang}"
                    #puts app_dir
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest
                    test.appendDir app_dir
                    
                    status, test_request, test_response = fileExists?(test, :default => true)
                    
                    if status == true 
                     
                   #   test_chat = Chat.new(test,test_response, :id => chat.id)
                      
                        addFinding( test_request,test_response,
                          :test_item => chat.request.url.to_s,
                          :check_pattern => "#{app_dir}",
                          :proof_pattern => "#{test_response.status}",
                          :chat => chat,
                          :title => "#{app_dir}"
                      )
                      
                      # check for _stats.swe
                      stats_test = chat.copyRequest
                      stats_test.replaceFileExt("_stats.swe")
                      status, stats_request, stats_response = fileExists?( stats_test, :default => true)
                    
                      if status == true and stats_response.has_body?
                         addFinding( stats_request,stats_response,
                          :test_item => stats_request.url.to_s,
                          :check_pattern => "#{app_dir}",
                          :proof_pattern => "#{stats_response.status}",
                          :chat => chat,
                          :title => "#{app_dir}",
                          :check_name => "Siebel Stats Page",
                          :class => "Siebel: Stats Page"
                        )
                      end
                      
                      # check for base.txt
                      base_test = chat.copyRequest
                      base_test.appendDir app_dir
                      base_test.replaceFileExt("base.txt")
                     # puts base_test.url
                      status, base_request, base_response = fileExists?(base_test, :default => true)
                    
                      if status == true and base_response.has_body?
                        version = nil
                        if base_response.body.strip =~ /^([0-9.]*) /
                          version = $1
                        end
                         addFinding( base_request,base_response,
                          :test_item => base_request.url.to_s,
                          :check_pattern => "base.txt",
                          :proof_pattern => "#{base_response.status}",
                          :chat => chat,
                          :title => "#{app_dir}",
                          :check_name => "Siebel Version #{version}",
                          :class => "Siebel: Version #{version}"
                        )
                      end
                      
                      # check for About_Siebel.htm and siebindex.htm                      
                      %w( About_Siebel.htm help/siebindex.htm siebindex.htm ).each do |df|
                        default_test = chat.copyRequest
                      default_test.appendDir app_dir
                      default_test.replaceFileExt(df)
                      status, default_request, default_response = fileExists?(default_test, :default => true)
                    
                      if status == true 
                         addFinding( default_request,default_response,
                          :test_item => "#{default_request.url.to_s}",
                          :check_pattern => "#{df}",
                          :proof_pattern => "#{default_response.status}",
                          :chat => chat,
                          :title => "#{df}",
                          #:check_name => "Siebel Version #{version}",
                          :class => "Siebel: Default Files"
                        )
                      end
                      end
                    
                    end
                    rescue => bang
                      puts bang
                      puts bang.backtrace
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  end
                end
              end            
              
            rescue => bang
              puts bang
              puts "ERROR!! #{Module.nesting[0].name}"
              raise
              
            end
          end
          
        end
        # --> eo namespace    
      end
    end
  end
end
