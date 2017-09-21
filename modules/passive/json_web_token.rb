# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Json_web_token < Watobo::PassiveCheck


        def initialize(project)
          @project = project
          super(project)
          begin
            @info.update(
                :check_name => 'Detect JSON Web Tokens', # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "This module detects JSON Web Tokens which are used for authentication purposes.", # description of checkfunction
                :author => "Andreas Schmidt", # author of check
                :version => "1.0" # check version
            )

            @finding.update(
                :threat => 'Informational', # thread of vulnerability, e.g. loss of information
                :class => "JSON Web Token", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
            )


            @known_directories = {}

            @pattern_list = []
            #@pattern_list << "access_token"
            @pattern_list << '.*_token'
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def do_test(chat)
# check for Bearer Authentication Scheme
# Authorization: Bearer e...
          begin
            pattern = 'Authorization.*Bearer(.*)'
            chat.request.headers do |header|
              if header =~ /#{pattern}/i then
                auth_match = $1.strip

                site = chat.request.site
                @known_directories[site] ||= []
                # strip path
                dir = chat.request.dir
                # we only want to have 2 levels
                strip_dir = dir.split('/')[0..1].join('/')

                unless @known_directories[site].include?(strip_dir)

                  @known_directories[site] << strip_dir


                  addFinding(
                      :check_pattern => "#{pattern}",
                      :proof_pattern => "#{auth_match}",
                      :title => "[Bearer Authentication Scheme] - #{chat.request.path}",
                      :chat => chat
                  )
                end
              end

            end
          rescue => bang
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
          end

          # check cookies
          pattern = '.*_token'
          chat.response.new_cookies do |c|
            begin
              if c.name =~ /#{pattern}/
                site = chat.request.site
                @known_directories[site] ||= []
                # strip path
                dir = chat.request.dir
                # we only want to have 2 levels
                strip_dir = dir.split('/')[0..1].join('/')

                next if @known_directories[site].include?(strip_dir)

                @known_directories[site] << strip_dir

                e = c.value.split('.')
                next if e.size != 3
                # parse jwt header
                th = JSON.parse(Base64.decode64(e[0]))
                # parse jwt payload
                tp = JSON.parse(Base64.decode64(e[1]))

                # if we reach this point base64 decoding was successful
                addFinding(
                    :check_pattern => "#{pattern}",
                    :proof_pattern => "#{c.value}",
                    :title => "[Cookie] - #{chat.request.path}",
                    :chat => chat
                )
              end
            rescue => bang
              # print error only in debug mode
              if $DEBUG
                puts "ERROR!! #{Module.nesting[0].name}"
                puts bang
              end
            end
          end

        end
      end

    end
  end
end
