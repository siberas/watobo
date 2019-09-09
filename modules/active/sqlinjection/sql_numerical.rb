require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Sqlinjection
        
        
        class Sql_numerical < Watobo::ActiveCheck
          
          @info.update(
                         :check_name => 'Numerical SQL-Injection',    # name of check which briefly describes functionality, will be used for tree and progress views
            :check_group => AC_GROUP_SQL,
            :description => "Checks numerical parameter values for SQL-Injection flaws.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9"   # check version
            )
            
            threat =<<'EOF'
SQL Injection is an attack technique used to exploit applications that construct SQL statements from user-supplied input. 
When successful, the attacker is able to change the logic of SQL statements executed against the database.
Structured Query Language (SQL) is a specialized programming language for sending queries to databases. 
The SQL programming language is both an ANSI and an ISO standard, though many database products supporting SQL do so with 
proprietary extensions to the standard language. Applications often use user-supplied data to create SQL statements. 
If an application fails to properly construct SQL statements it is possible for an attacker to alter the statement structure 
and execute unplanned and potentially hostile commands. When such commands are executed, they do so under the context of the user 
specified by the application executing the statement. This capability allows attackers to gain control of all database resources 
accessible by that user, up to and including the ability to execute commands on the hosting system.

Source: http://projects.webappsec.org/SQL-Injection
EOF
            
            measure = "All user input must be escaped and/or filtered thoroughly before the sql statement is put together. Additionally prepared statements should be used."
            
            @finding.update(
                            :threat => threat,        # thread of vulnerability, e.g. loss of information
                            :class => "SQL-Injection",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_VULN,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :rating => VULN_RATING_CRITICAL,
            :measure => measure
            )
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            
          end
          
          def generateChecks(chat)
            
            #
            #  Check GET-Parameters
            #
            begin
              chat.request.parameters.each do |test_parm|

                parm = test_parm.copy
                vint = nil
                # first check if parameter is integer value
                value = parm.value.is_a?( String ) ? parm.value : parm.value.to_s
                if value.strip =~ /^\d+$/ then
                #  puts "*!* #"
                  vint = value.to_i
                end
                
                if vint then
                  #puts "* found integer get parameter #{parm}"
                  checker = proc {
                    begin
                      test_request = nil
                      test_response = nil
                      
                      # first do request double time to check if hashes are the same
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test,:default => true)
                      # hash_1 = Digest::MD5.hexdigest(test_response.body.join)
                      hash_1 = Watobo::Utils.responseHash(test_request, test_response)
                      test = chat.copyRequest
                      test_request,test_response = doRequest(test,:default => true)
                      hash_2 = Watobo::Utils.responseHash(test_request, test_response)
                      #hash_2 = Digest::MD5.hexdigest(test_response.body.join)
                      
                      test = chat.copyRequest
                      # also need to check if altered parm will change response
                      parm = test_parm.copy
                      parm.value = "#{vint+1}"
                      test.set parm
                      test_request,test_response = doRequest(test,:default => true)
                      hash_3 = Watobo::Utils.responseHash(test_request, test_response)
                   #   puts "Hash 1: #{hash_1}"
                    #  puts "Hash 2: #{hash_2}"
                    #  puts "Hash 3: #{hash_3}"
                      # if hash_1 == hash_2 then
                      if hash_1 == hash_2 and hash_1 != hash_3 then # same hashes? now we can start the test
                        test = chat.copyRequest
                        # first add one to the original value and append "-1"
                        parm = test_parm.copy
                        parm.value = "#{vint+1}-1"
                        test.set parm
                        test_request,test_response = doRequest(test,:default => true)
                        
                        hash_test = Watobo::Utils.responseHash(test_request, test_response)
                        if hash_test == hash_1 then
                          path = "/" + test_request.path
                        #  test_chat = Chat.new(test,test_response, :id => chat.id)
                          addFinding(test_request, test_response,
                                     :check_pattern => "#{parm}",
                          :chat => chat,
                          :title => "[#{parm}] - #{path}"
                          )
                          
                        end
                        
                      end
                    rescue => bang
                      puts bang
                      raise
                    end
                    [ test_request, test_response ]
                  }
                  yield checker
                  
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
