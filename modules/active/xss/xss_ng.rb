# @private 
module Watobo #:nodoc: all
  module Modules
    module Active
      module Xss


        class Xss_ng < Watobo::ActiveCheck

          threat = <<'EOF'
Cross-site Scripting (XSS) is an attack technique that involves echoing attacker-supplied code into a user's browser instance. 
A browser instance can be a standard web browser client, or a browser object embedded in a software product such as the browser 
within WinAmp, an RSS reader, or an email client. The code itself is usually written in HTML/JavaScript, but may also extend to 
VBScript, ActiveX, Java, Flash, or any other browser-supported technology.

When an attacker gets a user's browser to execute his/her code, the code will run within the security context (or zone) of the 
hosting web site. With this level of privilege, the code has the ability to read, modify and transmit any sensitive data accessible 
by the browser. A Cross-site Scripted user could have his/her account hijacked (cookie theft), their browser redirected to another 
location, or possibly shown fraudulent content delivered by the web site they are visiting. Cross-site Scripting attacks essentially 
compromise the trust relationship between a user and the web site. Applications utilizing browser object instances which load content 
from the file system may execute code under the local machine zone allowing for system compromise.

Source: http://projects.webappsec.org/Cross-Site+Scripting
EOF

          measure = "All user input should be filtered and/or escaped using a method appropriate for the output context"

          @info.update(
              :check_name => 'NextGeneration Cross Site Scripting Checks', # name of check which briefly describes functionality, will be used for tree and progress views
              :check_group => AC_GROUP_XSS,
              :description => "XSS Checks with rating. Additional parameters are created by extracting input fields (name/value pairs) of the original response.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0" # check version
          )

          @finding.update(
              :threat => threat, # thread of vulnerability, e.g. loss of information
              :class => "Reflected XSS", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_HIGH,
              :measure => measure
          )

          def initialize(project, prefs = {})
            super(project, prefs)


            @envelop = "watobo"
            @env_count = 0
            @evasions = ["%0a", "%00"]
            @xss_chars = %w( < > ' " )
            @escape_chars = ['\\']
            @additional_parms = []

            def reset
              @additional_parms = []
              @env_count = 0
            end


          end


          def generateChecks(chat)
            begin
              # 
              if chat.response.respond_to? :input_fields
                chat.response.input_fields do |field|

                  @additional_parms << field.to_www_form_parm if chat.request.method_post?
                  @additional_parms << field.to_url_parm

                end
              end

              @parm_list = chat.request.parameters()
              @parm_list.concat @additional_parms
              @parm_list.each do |parm|
                #log_console( "#{parm.location} - #{parm.name} = #{parm.value}")

                checks = []
                @xss_chars.each do |xss|
                  @env_count += 1

                  check_id = "#{@envelop}#{@env_count}"
                  checks << [xss.dup, "#{xss}", check_id]
                  checks << [xss.dup, "#{parm.value}#{xss}", check_id]
                  checks << [xss.dup, "#{xss}#{parm.value}", check_id]

                end


                checker = proc {
                  results = {}
                  checks.each do |xss, check, check_id|

                    test_request = nil
                    test_response = nil

                    # UPDATE: we inject every parameter, to have a chance for xss in error responses
                    # first we check, if parameter is injectable

                    # accept only one (escape) char between check_id and check string
                    proof = "#{check_id}(#{Regexp.quote(check)}){0,1}#{check_id}"
                    next if results.has_key? xss
                    test = chat.copyRequest

                    parm.value = check_id + CGI.escape(check) + check_id
                    test.set parm

                    test_request, test_response = doRequest(test)

                    if not test_response then
                      if $DEBUG
                        puts "[#{Module.nesting[0].name}] got no response :("
                        puts test
                      end
                    elsif test_response.join =~ /#{proof}/i
                      match = $1
                      #puts "MATCH: [ #{match} ] / [ #{check} ]"
                      if match == check
                        results[xss] = {:match => :full, :check => check, :proof => proof}
                      end

                      unless results.has_key? xss
                        @escape_chars.each do |ec|
                          ep = Regexp.quote("#{ec}#{xss}")
                          #  puts "Escaped: #{match} / #{ep}"
                          results[xss] = {:match => :escaped, :check => check, :proof => proof, :escape_char => "#{ec}"} if match =~ /#{ep}/
                        end
                      end

                    end

                  end
                  rating = 0

                  puts results.to_yaml if $DEBUG
                  xss_combo = ""
                  combo_patterns = []
                  results.each do |k, v|
                    mp = CGI.escape(k)
                    rp = CGI.escape(@xss_chars.join)
                    xss_combo += CGI.escape(k)
                    #puts "[#{k}] - #{v}"
                    case v[:match]

                    when :full
                      rating += 100 / @xss_chars.length
                      combo_patterns << k
                    when :escaped
                      rating += 100 / (@xss_chars.length * 4)
                      combo_patterns << Regexp.quote("#{v[:escape_char]}#{k}")
                    end
                  end

                  if rating > 0
                    test = chat.copyRequest
                    #puts "COMBO-REQUEST: #{xss_combo}"
                    parm.value = "#{@envelop}#{@env_count}#{xss_combo}"
                    pattern = "(#{@envelop}#{@env_count}(#{combo_patterns.join("|")})+)"
                    test.set parm

                    match = ""

                    test_request, test_response = doRequest(test)
                    if not test_response then
                      puts "got no response :("
                    elsif test_response.join =~ /#{pattern}/i
                      match = $1
                      #puts "MATCH: #{match}"
                    end

                    fclass = "Reflected XSS - #{rating}%"
                    fclass = "Reflected XSS (POST) - #{rating}%" if parm.location == :data
                    addFinding(test_request, test_response,
                               :check_pattern => xss_combo,
                               :proof_pattern => "#{match}",
                               :test_item => parm.name,
                               :class => fclass,
                               :chat => chat,
                               :title => "[#{parm.name}] - #{test_request.path}"
                    )
                  end

                  [test_request, test_response]
                }
                yield checker

              end

            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              puts "ERROR!! #{Module.nesting[0].name}"
              raise


            end
          end

        end

      end
    end
  end
end
