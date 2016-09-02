# @private
module Watobo #:nodoc: all
  module Modules
    module Passive

      class Disclosure_ipaddr < Watobo::PassiveCheck

        def initialize(project)
          @project = project
          super(project)
          @info.update(
              :check_name => 'IP Adress Disclosure', # name of check which briefly describes functionality, will be used for tree and progress views
              :description => 'Looks for (internal) IP adresses.', # description of checkfunction
              :author => "Andreas Schmidt", # author of check
              :version => "0.9" # check version
          )

          @finding.update(
              :threat => 'Internal information may be revealed, which could help an attacker to prepare further attacks', # thread of vulnerability, e.g. loss of information
              :class => "IP Adress Disclosure", # vulnerability class, e.g. Stored XSS, SQL-Injection, ...
              :type => FINDING_TYPE_INFO, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
              :measure => "Remove all information which reveal internal information."
          )

          @pattern = '[^\d\.](\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[^(\d\.)]+?'

          @known_ips = []
        end

        def do_test(chat)
          begin
            #  puts "running module: #{Module.nesting[0].name}"
            return false if chat.response.nil?
            data = chat.response.headers
            # remove Location header
            while mi=data.index { |i| i=~ /^Location/i }
              data.delete_at mi
            end

            data = data.join
            unless chat.response.has_body?
              if chat.response.content_type =~ /(text|script)/ then
                body = chat.response.body_encoded
                data << body
              end
            end

            data.scan(/#{@pattern}/) { |match|
              ip_addr = match.first
              octets = ip_addr.split('.')
              isIP = true
              octets.each do |o|
                isIP = false if o.to_i > 255
              end
              if isIP then
                if ip_addr =~ /^10\./ or (ip_addr =~ /^192.168/) or (octets[0] == "172" && (16..32).include?(octets[1].to_i))
                  title = "Private IP: #{ip_addr}"
                else
                  title = "Public IP: #{ip_addr}"
                end
                dummy = chat.request.site + ":" + ip_addr
                if not @known_ips.include?(dummy)
                  addFinding(:proof_pattern => ip_addr,
                             :chat => chat,
                             :title => title)
                  @known_ips.push dummy
                end
              end
            }

          rescue => bang
            #  raise
            puts "ERROR!! #{Module.nesting[0].name}"
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

    end
  end
end
