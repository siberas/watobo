require 'digest/md5'
require 'digest/sha1'

# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Domino
        
        
        class Domino_db < Watobo::ActiveCheck
          @info.update(
                         :check_name => 'Lotus Domino DB Enumeration',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Enumeration of well known Domino DBs.",   # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :check_group => AC_GROUP_DOMINO,
            :version => "1.0"   # check version
            )
            
            @finding.update(
                            :threat => 'Information Disclosure and/or modifying of databases.',        # thread of vulnerability, e.g. loss of information
            :class => "Lotus Domino: Default Database",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN 
            )
            
          def initialize(project, prefs={})
            super(project, prefs)
            
            @domino_dbs = []
            
            filename = "domino_db.lst"            
            path = File.dirname(__FILE__)            
            db_file = File.join(path, filename)
            
            begin
              fh = open(db_file,"r")  
              fh.each_line do |dbname|
                @domino_dbs.push dbname.strip
              end
            #  puts "* #{@domino_dbs.length} Lotus Domino DB Names loaded"
            rescue => bang
              puts "!!! ERROR: Problems import Domino DB List"
              puts "File:"
              puts "#{db_file}"
              puts bang
            end
          end
          
          def generateChecks(chat)            
            begin              
             # if chat.request.url.to_s =~ /(.*)\/\w*\.nsf/ then
                @domino_dbs.each do |db|
                  checker = proc{
                    test_request = nil
                    test_response = nil
                    test = chat.copyRequest
                    
                    test.replaceFileExt db
                    
                    test_request,test_response = doRequest(test,:default => true)
                    
                    
                    if test_response.status =~ /ok/i then
                     # test_chat = Chat.new(test, test_response, chat.id)
                      if test_response.join =~ /(names\.nsf\?Login)/ # if default db found, check for content
                        addFinding( test_request,test_response,
                        :test_item => chat.request.url.to_s,
                                   :check_pattern => "#{db}",
                        :proof_pattern => "#{test_response.status}", 
                        :chat=>chat,
                        :title => db
                        )
                      else
                        addFinding(test_request,test_response,
                                   :check_pattern => "#{db}",
                        :proof_pattern => "#{test_response.status}",
                        :test_item => chat.request.url.to_s,
                        :class => "Lotus Domino: Unprotected Default DB",
                        :type => FINDING_TYPE_VULN,
                        :chat => chat,
                        :rating => VULN_RATING_HIGH,
                        :title => db
                        )
                        [ test_request, test_response ]
                      end
                    end
                  }
                  yield checker
                end
              #end            
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
