require 'spec_helper'

headers = <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Cache-Control: no-store
Connection: close
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
X-Request-ID: bc0e900d-6737-41b8-8800-7b5d80550466
Content-Language: de-DE
Connection: close
Transfer-Encoding: chunked
Content-Type: application/json;charset=utf-8
EOF

chunked_body = <<EOF
0A
AAAAAAAAAA
0
EOF

chunked = []
headers.each_line do |l|
  chunked << l
end
chunked << "\r\n"
chunked << chunked_body



rwm_file = File.expand_path(File.join(File.dirname(__FILE__ ),'..','samples', 'raw_multipart.yaml'))
raw_with_multipart = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, rwm_file, {})

describe Watobo::Plugin::NucleiScanner::NucleiMatcher do
  context "raw multipart" do
    base = Watobo::Request.new 'https://www.acme.de'
    requests = raw_with_multipart.send(:nuclei_requests, base)
    response = Watobo::Response.new chunked

    it 'number requests' do
      expect(requests.length).to eq(1)
    end

    it 'url location' do
      expect(requests.first.url.to_s).to include('www.acme.de')
    end

    it 'host header' do
      expect(requests.first.headers('Host').first).to include('www.acme.de')
    end

    it 'word matcher' do
      m = raw_with_multipart.match?([response])

      expect(m).to be(false)
    end


  end
end
