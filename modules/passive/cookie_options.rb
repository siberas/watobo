# .
# cookie_options.rb
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
    module Passive
      
      
      class Cookie_options < Watobo::PassiveCheck
        
        def initialize(project)
          
          @project = project
          super(project)
          @info.update(
                       :check_name => 'Cookie Security',    # name of check which briefly describes functionality, will be used for tree and progress views
          :description => 'Cookies especially Session Cookies should be set only over a secure channel. Additionally there should be set some security options.',   # description of checkfunction
          :author => "Andreas Schmidt", # author of check
          :version => "0.9"   # check version
          )
          
          @finding.update(
                          :threat => 'Cookies used in this application are not secured by special Cookie Options like Secure or HTTPOnly. If Cookie Security is not in place, sensitive cookie information may be revealed.',        # thread of vulnerability, e.g. loss of information
          :class => "Cookie Security",# vulnerability class, e.g. Stored XSS, SQL-Injection, ...
          :type => FINDING_TYPE_VULN,         # e.g. Hints, Info, Vuln 
          :rating=> VULN_RATING_MEDIUM  # [Symbol] Critical, High, Medium, Low, Info
          )
        end
        
        def do_test(chat)
          begin
            # puts "running module: #{Module.nesting[0].name}"
            if chat.response.headers.each do |h|
                if h =~ /(^Set-Cookie.*)/ then
                  dummy = h.split(";")
                  cookie = dummy.shift
                  options = dummy.join(";")
                  
                  if (chat.request.proto =~ /https/i and options !~ /secure/i) or options !~ /httponly/i then
                    cookie.gsub!(/=.*/,"")
                    addFinding( :proof_pattern => options, 
                               :check_pattern => "Set-Cookie:.*", 
                    :chat => chat, 
                    :title => 'Security Options',
                    :unique => cookie)
                  end
                end
              end
            end
          rescue
            puts "ERROR!! #{Module.nesting[0].name}"
          end
        end
      end
      
    end
  end
end
