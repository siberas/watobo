require 'spec_helper'

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
Content-Type: text/html
EOF

chunked_body = <<EOF
<html></html>
EOF

chunked = []
headers.each_line do |l|
  chunked << l
end
chunked << "\r\n"
chunked << chunked_body

true_headers = <<EOF
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
Content-Type: text/html
EOF

true_body = <<EOF
<html><script>alert(0);</script></html>
EOF

true_response = []
true_headers.each_line do |l|
  true_response << l
end
true_response << "\r\n"
true_response << true_body

sample_file = File.basename(__FILE__).gsub(/_spec.*/, '.yaml')

file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'samples', sample_file))
nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})

# create array of 2
# one response for each request
false_responses = []
false_responses << Watobo::Response.new(chunked)
false_responses << Watobo::Response.new(chunked)

true_responses = []
true_responses << Watobo::Response.new(true_response)
true_responses << Watobo::Response.new(true_response)

describe Watobo::Plugin::NucleiScanner::NucleiMatcher do
  context "multi raw requests with dsl matcher" do
    # base = Watobo::Request.new 'https://www.acme.de'
    # requests = raw_with_multipart.send(:nuclei_requests, base)

    it 'DSL Match - False' do
      m = nuclei_check.match?(false_responses)
      expect(m).to be(false)
    end

    it 'DSL Match - True' do
      m = nuclei_check.match?(true_responses)
      expect(m).to be(true)
    end

  end
end
