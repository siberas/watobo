# .
# crossdomain.rb
#   
# Copyright 2010 by siberas, http://www.siberas.de
# 
# This file is part of WATOBO (Web Application Tool Box)
#        http://watobo.sourceforge.com
# 
# WATOBO is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 2 of the License.
# 
# WATOBO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with WATOBO; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# .
# @private 
module Watobo#:nodoc: all
  module Modules
    module Active
      module Flash 
        
        
        class Crossdomain < Watobo::ActiveCheck
          
          @info.update(
                        :check_name => 'Crossdomain Policy',        # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "Check for crossdomain.xml weaknesses", # description of checkfunction
          :check_group => AC_GROUP_FLASH,
                :author => "Hans-Martin Muench",      # author of check
                :version => "0.1"             # check version
            )
            
            
            
            @finding.update(
                        :class => "Crossdomain.xml check",          # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_VULN              # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            )
          
          def reset()
            @checked_dirs.clear  
          end
          
          def initialize(project, prefs={})
            super(project, prefs)
            
            
            
            @checked_dirs = Hash.new
          end
         
 
          def generateChecks(chat)  
          	directory = chat.request.dir
               	if not @checked_dirs.has_key?(directory)                  
                 	@checked_dirs[directory] = :checked
                  	checker = proc {
                     		test_request = nil
                     		test_response = nil
		     		path = directory + "/crossdomain.xml"                     

		      		# IMPORTANT!!!
                      		# use copyRequest(chat) for cloning the original request 
                      		test = chat.copyRequest
                      		test.setDir(path)
                      		status, test_request, test_response = fileExists?(test, :default => true)
	
                      		if status == true 

					# Do a simple match on the response to detect
					# if we have <allow-access-from domain="*"/>
					if test_response.join =~ /<allow-access-from\s+domain="\*"\s+/i then
 						
						proof_pattern = $~

                        			addFinding( test_request, test_response,
                               				:check_pattern => "<allow-access-from\\s+domain=\"*\"\\s+",
                               				:proof_pattern => proof_pattern.to_s,
                               				:test_item => "test-item",
                               				:chat => chat,
                               				:title => "Badly configured crossdomain.xml",
                               				:rating => VULN_RATING_CRITICAL,
                               				:threat => "The current crossdomain.xml policy allows cross domain access from everywhere",
                               				:measure => "Restrict the allowed hosts setting inside the policy", 
                               				:class => "Flash security"
                        			)
                      			end
				end
                      		[ test_request, test_response ]

                  	}
                  	yield checker
               	end # end ifnot
	      end
	    end # end proc
          end  # end class
        end # end module flash
      end  # end Active
    end # End modules
