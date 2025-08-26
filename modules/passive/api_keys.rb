# @private
module Watobo #:nodoc: all
  module Modules
    module Passive

      class Api_keys < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)

          @info.update(
            :check_name => 'Detect API Keys', # name of check which briefly describes functionality, will be used for tree and progress views
            :description => "Detects API Keys/Credentials which may reveal sensitive information.", # description of checkfunction
            :author => "Andreas Schmidt", # author of check
            :version => "1.0" # check version
          )

          @finding.update(
            :threat => 'API may reveal internal information like database passwords.', # thread of vulnerability, e.g. loss of information
            :class => "API Keys", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
            :type => FINDING_TYPE_HINT # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
          )

        end

        def do_test(chat)
          begin

            @checked ||= {}

            if chat.response.content_type =~ /(text|script)/

              Watobo::Resources::LEAK_PATTERNS.each do |type, regex|
                t_start = Process.clock_gettime(Process::CLOCK_REALTIME)
                # puts "+check pattern #{type} "
                #puts "   Content-Type: #{chat.response.content_type}"
                # if  chat.response.join =~ /(#{pattern})/i then
                resp_str = chat.response.join
                resp_hash = Digest::MD5.hexdigest(resp_str)
                resp_key = type + resp_hash
                next if @checked[resp_key]
                @checked[resp_key] = true

                if m = regex.match(resp_str)
                  match = m[0]
                  path = "/" + chat.request.path

                  ignore = false
                  type_patterns = Watobo::Resources::LEAK_IGNORE_PATTERNS[type] || []
                  puts match if type.match?(/ipv4/i)
                  type_patterns.each do |iregx|
                    next if ignore
                    puts "   check ignore pattern #{iregx}"
                    puts "   match #{match}"
                    puts "   ignore #{ignore}"
                    puts '---'
                    ignore = iregx.match?(match)
                  end
                  unless ignore
                    puts "!!! MATCH !!! >> [#{type}] - #{path}"
                    addFinding(
                      :proof_pattern => "#{Regexp.quote(match)}",
                      :chat => chat,
                      :title => "[#{type}] - #{path}"
                    )
                  end
                end
                t_end = Process.clock_gettime(Process::CLOCK_REALTIME)
                duration = ((t_end - t_start) * 1000).round(2)
                #puts "    Duration: #{duration.to_s}"
              end
            end
          rescue => bang
            # raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace #if $DEBUG
            binding.pry if $DEBUG
          end
        end
      end

    end
  end
end
