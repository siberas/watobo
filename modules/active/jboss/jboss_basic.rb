# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Jboss
        
        
        class Jboss_basic < Watobo::ActiveCheck
          
          @info.update(
                         :check_name => 'Basic JBoss enumeration',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_JBOSS,
            :description => "Check every parameter for SQL-Injection flaws.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            
            
            @finding.update(
                            :class => "JBoss-AS (critical)",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            )
          
          def reset()
            @checked_dirs.clear  
          end
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            
            measure = "Remove all unnecessary JBoss-Interfaces like JMX-Console."
            
            @jboss_checks = Hash.new
            @jboss_checks["JBoss-AS (critical)"] = { :dirs => ['/jmx-console/HtmlAdaptor', '/web-console/Invoker', '/invoker/JMXInvokerServlet'],
              :rating => VULN_RATING_CRITICAL,
              :threat => "This server supports dangerous JBoss interfaces. An attacker can use these interfaces to gain control over system by deploying its own malicious servlets.",
              :measure => measure
            }

            #
            measure = "Disable all unneeded functions."                                                     
            @jboss_checks["JBoss-AS (info)"] = { :dirs => [ '/status', '/web-console/ServerInfo.jsp'],
              :rating => VULN_RATING_LOW,
              :threat => "There are some functions enabled on this server which leads to information disclosure.
An attacker can use these information to prepare more targeted attacks. ",
              :measure => measure
            }
            
            @checked_dirs = Hash.new
          end
          
          def generateChecks(chat)            
              chat.request.subDirs do |dir|
                if not @checked_dirs.has_key?(dir)                  
                  @checked_dirs[dir] = :checked
                  @jboss_checks.each do |ckey, check_settings| 
                    check_settings[:dirs].each do |cdir|
                      checker = proc {
                        check_dir = cdir
                        test_request = nil
                        test_response = nil
                        # IMPORTANT!!!
                        # use copyRequest(chat) for cloning the original request 
                        test = chat.copyRequest
                        puts "appending dir #{check_dir}"
                        test.setDir(dir)
                        test.appendDir(check_dir)
                        
                        #puts test
                        
                        status, test_request, test_response = fileExists?(test, :default => true)
                        if status == true  
                          #test_chat = Chat.new(test, test_response,chat.id)
                         # resource = "/" + test_request.resource
                          addFinding( test_request, test_response,
                                     :check_pattern => "#{check_dir}",
                                     :test_item => dir,
                          :chat => chat,
                          :title => "[#{check_dir}]",
                          :rating => check_settings[:rating],
                          :threat => check_settings[:threat],
                          :measure => check_settings[:measure],
                          :class => ckey
                          )
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
      end
    end
  end
