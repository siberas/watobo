# .
# mod_status.rb
#
# Copyright 2010 by it.sec, http://www.www.it-sec.de
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
      module Apache
        class Mod_status < Watobo::ActiveCheck
          
           @info.update(
            :check_name  => 'Server-Status page',    # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Check for status page created by mod_status",   # description of checkfunction
            :author      => "Hans-Martin Muench", # author of check
            :check_group => AC_GROUP_APACHE,
            :version     => "0.1"   # check version
            )

            @finding.update(
            :class        => "Information disclosure",    # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type         => FINDING_TYPE_HINT,           # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            :measure       => "Disable the mod_status module or restrict the access to the status page",
            :threat      => "The result page of the mod-status module is accessible without authentication. This page contains information about the server activity and performance"
            )
            
          def reset()
            @checked_sites.clear
          end

          def initialize(project, prefs={})
            super(project, prefs)

           

            @status_checks = ['/server-status/', '/server_status/', '/serverstatus/', '/mod-status/', '/mod_status/', '/modstatus', 'status']

            @checked_sites = Hash.new
          end

          def generateChecks(chat)
           
            if not @checked_sites.has_key?(chat.request.site)
              @checked_sites[chat.request.site] = :checked
              @status_checks.each do |status_path|
                checker = proc {
                 
                  test_request = nil
                  test_response = nil

                  # IMPORTANT!!!
                  # use copyRequest(chat) for cloning the original request
                  test = chat.copyRequest
                  test.setDir(status_path)

                  status, test_request, test_response = fileExists?(test, :default => true)

                  if test_response.status =~ /200/ and test_response.join =~ /Apache Server Status for/i then

                    addFinding( test_request, test_response,
                    :check_pattern => "#{status_path}",
                    :proof_pattern => "Apache Server Status for",
                    :test_item => status_path,
                    :chat => chat,
                    :title => "[Server] - Server-Status page",
                    :rating => VULN_RATING_LOW
                    )

                  elsif test_response.status =~ /403/ then

                    addFinding( test_request, test_response,
                    :threat  => "Mod-status is installed but access is denied",
                    :measure      => "Disable the mod_status module if not needed",
                    :check_pattern => "#{status_path}",
                    :proof_pattern => "403 Forbidden",
                    :test_item => status_path,
                    :type    => FINDING_TYPE_INFO,
                    :class => "Information",
                    :chat => chat,
                    :title => "[Server] - Server-Status page",
                    :rating => VULN_RATING_LOW
                    )

                  elsif test_response.status =~ /401/ then

                    addFinding( test_request, test_response,
                    :threat  => "Mod-status is installed but access is password protected",
                    :measure      => "Disable the mod_status module if not needed",
                    :check_pattern => "#{status_path}",
                    :proof_pattern => "401 Unauthorized",
                    :test_item => status_path,
                    :type    => FINDING_TYPE_HINT,
                    :class => "Information",
                    :chat => chat,
                    :title => "[Server] - Server-Status page",
                    :rating => VULN_RATING_LOW
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
