module Watobo::EvasionHandlers
  class UserAgent < EvasionHandlerBase

    prio 4

    BYPASS_USER_AGENTS = %w(
Nacos-Server
Authorized
Debug
Internal
AutodiscoverClient
Windows-Update-Agent
MicrosoftBITS
 )

    BYPASS_USER_AGENTS << 'Report Runner'
    BYPASS_USER_AGENTS << "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_3)"

    def run(request, &block)
      puts "! run evasion #{self}" if $DEBUG
      BYPASS_USER_AGENTS.each { |agent|
        test = request.clone
        test.setHeader('User-Agent', agent)
        yield test
      }
    end
  end
end
