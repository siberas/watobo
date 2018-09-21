# @private
module Watobo #:nodoc: all
  module Modules
    module Active
      module Cq5
        #class Dir_indexing < Watobo::Mixin::Session
        class Cq5_params < Watobo::ActiveCheck

          @info.update(
              :check_name => 'CQ5 Params', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => "This module checks for default url parameters used by AEM.", # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "1.0", # check version
              :check_group => "CQ5"
          )

          @finding.update(
              :threat => 'Selectors can reveal sensitive information about the application, e.g. password hashes (jackrabbit). Also, the query selector enables you to perform XPATH queries on the entire repository, which could slow your system down considerably, or even cause a denial of service if run multiple times', # thread of vulnerability, e.g. loss of information
              :class => "CQ5: Params", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :rating => VULN_RATING_INFO
          )

          def initialize(project, prefs = {})
            super(project, prefs)

            @checked_locations = []
            @params = []
            @params << UrlParameter.new(name: 'debug', value: 'layout')
            @params << UrlParameter.new(name: 'debugClientLibs', value: 'true')
            @params << UrlParameter.new(name: 'debugConsole', value: 'true')
            %w( edit preview design disabled ).each do |v|
              @params << UrlParameter.new(name: 'wcmmode', value: v)
            end


          end

          def reset()
            @checked_locations = []
          end

          def generateChecks(chat)
            path = chat.request.path
            return false if @checked_locations.include? path
            @checked_locations << path

            @params.each do |param|
              checker = proc {
                begin
                  pre_request = nil
                  pre_response = nil

                  pre = chat.copyRequest

                  pre_request, pre_response = doRequest(pre)
                  if Watobo::Utils.compare_responses(pre_response, chat.response)


                    test_request = nil
                    test_response = nil

                    test = chat.copyRequest

                    test.set param

                    test_request, test_response = doRequest(test)

                    unless Watobo::Utils.compare_responses(test_response, chat.response)
                      addFinding(test_request, test_response,
                                 :test_item => "#{test_request.url}",
                                 :proof_pattern => "#{test_response.status}",
                                 :chat => chat,
                                 :title => "[#{param.to_s}]"
                      )

                    end

                    if test_response.join =~ /firebug\-lite/i
                      addFinding(test_request, test_response,
                                 :test_item => "#{test_request.url}",
                                 :proof_pattern => "#{Regexp.quote('firebug-lite')}",
                                 :chat => chat,
                                 :title => "[#{param.to_s}]"
                      )

                    end
                  else
                    raise "[#{self}] responses are not comparable"
                  end
                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                end
                [test_request, test_response]

              }
              yield checker
            end

          end
        end
      end
    end
  end
end
