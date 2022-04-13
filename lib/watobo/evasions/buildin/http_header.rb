module Watobo::EvasionHandler
  class HttpHeaders
    EVASION_HEADERS = %w( X-Originating-IP X-Forwarded-For X-Remote-IP X-Remote-Addr )
    EVASION_LOCATIONS = %w( 127.0.0.1 ::1 )

    def run(request, &block)
      puts "! run evasion #{self}" if $DEBUG
      EVASION_HEADERS.each do |header|
        EVASION_LOCATIONS.each do |location|
          test = request.clone
          test.set_header "#{header}: #{location}"
          yield test
        end

      end
    end
  end

end