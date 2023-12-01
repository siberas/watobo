module Watobo::EvasionHandlers
  # SRC: https://github.com/gorilla/handlers/blob/master/proxy_headers.go#L13
  # // RFC7239 defines a new "Forwarded: " header designed to replace the
  # 	// existing use of X-Forwarded-* headers.
  # 	// e.g. Forwarded: for=192.0.2.60;proto=https;by=203.0.113.43
  # 	forwarded = http.CanonicalHeaderKey("Forwarded")
  # 	// Allows for a sub-match of the first value after 'for=' to the next
  # 	// comma, semi-colon or space. The match is case-insensitive.
  # 	forRegex = regexp.MustCompile(`(?i)(?:for=)([^(;|,| )]+)`)
  # 	// Allows for a sub-match for the first instance of scheme (http|https)
  # 	// prefixed by 'proto='. The match is case-insensitive.
  # 	protoRegex = regexp.MustCompile(`(?i)(?:proto=)(https|http)`)
  # )
  class HttpHeaders < EvasionHandlerBase

    prio 3

    EVASION_SRC_HEADERS = %w( Via X-Originating-IP X-Forwarded-Host X-Forwarded-For X-Original-Forwarded-For X-Real-IP True-Client-IP X-True-IP X-Remote-IP X-Remote-Addr )
    EVASION_LOCATIONS = [
      '127.0.0.1',
      '::1',
      'null',
      '0',
      '172.17.0.10',  # Docker IPs
      '100.64.0.1'    # Tailscale VPN
    # Todo: Add more IP locations for evasions
    # + public IP of server
    # + IPs of associated networks
    # + Internal IPs of Providers (Linode, Google, DigitalOcean, ...)
    # + IPs of SPF(mail) entries, e.g. "v=spf1 include:spf.mail.s-web.de ip4:109.234.127.0/24 ip4:80.82.206.0/26 ip4:185.98.184.0/24
    # ip4:195.140.49.1 ip4:195.140.51.1 ip4:195.140.52.1 ip4:62.181.150.1 ip4:62.181.152.1 ~all"
    ]

    EVASION_PROTOS = %w( https http )

    def run(request, &block)
      puts "! run evasion #{self}" if $DEBUG
      EVASION_SRC_HEADERS.each do |header|
        EVASION_LOCATIONS.each do |location|
          test = request.clone
          test.set_header "#{header}: #{location}"
          yield test
        end

      end

      EVASION_LOCATIONS.each do |loc|
        EVASION_PROTOS.each do |proto|
          location = "for:#{loc};proto=#{proto};by=#{loc}"
          test = request.clone
          test.set_header "Forwarded: #{location}"
          yield test
          # do some more header-foo, as seen in a POC for CVE-2022-40684
          location = "for:[#{loc}];proto=#{proto};by=[#{loc}]"
          test = request.clone
          test.set_header "Forwarded: #{location}"
          yield test
        end
      end
    end
  end

end