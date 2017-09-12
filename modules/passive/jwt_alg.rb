# @private
module Watobo #:nodoc: all
  module Modules
    module Passive


      class Jwt_Alg < Watobo::PassiveCheck


        def initialize(project)
          @project = project
          super(project)
          begin
            @info.update(
                :check_name => 'JSON Web Tokens Algorithm', # name of check which briefly describes functionality, will be used for tree and progress views
                :description => "This module checks the algorithm used for JWT signing.", # description of checkfunction
                :author => "Andreas Schmidt", # author of check
                :version => "1.0" # check version
            )

            measure =<<EOF
For signing JSON Web Tokens you should use a secure algorithm which protects your token from brute-force-attacks, e.g. rsa.
You can find more details here:
https://auth0.com/blog/brute-forcing-hs256-is-possible-the-importance-of-using-strong-keys-to-sign-jwts/
EOF
            @finding.update(
                :threat => 'Insecure Algorithm', # thread of vulnerability, e.g. loss of information
                :class => "JWT Insecure Signature", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
                :type => FINDING_TYPE_VULN, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
                :rating => VULN_RATING_INFO,
                :measure => measure
            )


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
                jwt = $1.strip
                jwt_head = JSON.parse(Base64.decode64(jwt.split('.')[0]))

                if jwt_head['alg'] =~ /^HS/

                  addFinding(
                      :check_pattern => "#{pattern}",
                      #:proof_pattern => "#{auth_match}",
                      :title => "[Bearer Authentication Scheme] - #{chat.request.path}",
                      :chat => chat,
                      :details => jwt_head.to_s
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
                e = c.value.split('.')
                next if e.size != 3
                # parse jwt header
                th = JSON.parse( Base64.decode64(e[0]))
                # parse jwt payload
                tp =  JSON.parse( Base64.decode64(e[1]))

                # if we reach this point everything is fine
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
