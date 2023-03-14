require 'spec_helper'

describe Watobo::Scanner3 do

  let(:request) { Watobo::Request.new 'http://www.mydomain.de/to/go.php' }
  let(:redirect_data) {
    <<EOF
HTTP/1.1 302 REDIRECT
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Cache-Control: no-store
Connection: close
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Location: https://redirect.to.here
Content-Length: 0
EOF
  }

  let(:response_ok_header) {
    <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Content-Length: 0
EOF
  }

  context "autocollect 404" do
    let(:scanner) { Watobo::Scanner3.new }

    let(:redirect_response) { Watobo::Response.new(redirect_data.lines.map(&:chomp)) }
    let(:response_ok_simple ){
      Watobo::Response.new(response_ok_header.lines.map(&:chomp))
    }

    it "match redirect location" do
      notfound_tag = '404notfound' + SecureRandom.hex(3)
      request.replaceFileExt(notfound_tag)
      patterns = scanner.extract_not_found_pattern(request, redirect_response, notfound_tag)
      expect(patterns.first).to eq("Location:\\ https://redirect\\.to\\.here")
    end

    it "match notfound_tag in body" do
      tag = "aaa123bbb"
      response_ok_simple << "\r\n"
      response_ok_simple << "this is some random data around #{tag} which should be detected"
      request.replaceFileExt(tag)
      patterns = scanner.extract_not_found_pattern(request, response_ok_simple, tag)
      expect(patterns.first).to eq("around.*which")
    end
  end
end