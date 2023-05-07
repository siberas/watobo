require 'spec_helper'

false_headers = <<EOF
HTTP/1.1 404
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

false_response_template = []
false_headers.each_line do |l|
  false_response_template << l
end
false_response_template << "\r\n"

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
<html><script>test-poc</script></html>
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
false_responses << Watobo::Response.new(false_response_template)
false_responses << Watobo::Response.new(false_response_template)

true_responses = []
true_responses << Watobo::Response.new(true_response)
true_responses << Watobo::Response.new(true_response)

describe Watobo::Plugin::NucleiScanner::NucleiMatcher do
  context "multi raw requests with dsl matcher" do
    # base = Watobo::Request.new 'https://www.acme.de'
    # requests = raw_with_multipart.send(:nuclei_requests, base)
    #

    it 'check request classes first request' do
      expect(nuclei_check.requests.first.is_a?(Watobo::Plugin::NucleiScanner::NucleiRawRequest)).to be(true)
    end

    it 'check request classes second request' do
      expect(nuclei_check.requests.last.is_a?(Watobo::Plugin::NucleiScanner::NucleiBaseRequest)).to be(true)
    end

    nuclei_check.requests.first.responses << Watobo::Response.new(false_response_template)
    nuclei_check.requests.last.responses << Watobo::Response.new(false_response_template)

    it 'check for matcher first request' do
      m = nuclei_check.requests.first.has_matcher?
      expect(m).to be(false)
    end

    it 'check for matcher second request' do
      m = nuclei_check.requests.last.has_matcher?
      expect(m).to be(true)
    end

    it 'DSL Match - False' do

      m = nuclei_check.requests.first.has_matcher?
      expect(m).to be(false)
    end

    it 'DSL Match - True' do
      m = nuclei_check.requests.last.has_matcher?
      expect(m).to be(true)
    end

  end
end
