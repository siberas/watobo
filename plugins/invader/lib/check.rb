module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Check < Watobo::ActiveCheck
=begin
        @info.update(
            :check_name => 'Invader', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Dummy Check for performing payload ", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "0.9" # check version
        )
=end

        def initialize(project)
          super(project)

          @payload_prefs = nil
          @payload_tweaks = []

        end

        def reset()
          #@result.clear
        end

        def set_payload_prefs(prefs)
          @payload_prefs = prefs
        end

        def set_payload_tweaks(tweaks)
          @payload_tweaks = tweaks
        end


        def generateChecks(chat)
          begin
            Invader::Generator.run(@payload_prefs, @payload_tweaks) do |source, payload|
              parameters = chat.request.parameters
              parameters.each do |p|
                parm = p.copy

                checker = proc {
                  test_request = nil
                  test_response = nil
                  test = chat.copyRequest

                  parm.value = payload

                  test.set parm

                  t_start = Time.now.to_f
                  test_request,test_response = doRequest(test)
                  t_end = Time.now.to_f

                  rc = Chat.new(test_request, test_response,
                                  :id => 0,
                                  :chat_source => 'Invader',
                                  :tstart => t_start,
                                  :tstop => t_end
                  )

                  notify(:new_check, [source, rc ])

                  #@project.new_finding(:short_name=>"#{parm}", :check=>"#{check}", :proof=>"#{pattern}", :kategory=>"XSS-Post", :type=>"Vuln", :chat=>test_chat, :rating=>"High")
                  [ test_request, test_response ]
                }
                yield checker

              end
            end

          rescue => bang
            puts "!error in module #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace
          end
        end
      end

    end
  end
end


