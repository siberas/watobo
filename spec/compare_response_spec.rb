#!/usr/bin/ruby
# rspec --format documentation ./spec/response_spec.rb
require 'devenv'
require 'watobo'

str_one = <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Cache-Control: no-store
Transfer-Encoding: chunked
Content-Type: image/gif
Connection: close
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
EOF

str_two = <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Cache-Control: no-store
Content-Type: image/gif
Connection: close
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
EOF

resp_one = Watobo::Utils.string2response(str_one)
resp_two = Watobo::Utils.string2response(str_two)


describe Watobo do
  describe "CompareResponse" do

      it "Equal" do
        r = Watobo::Utils.compare_responses(resp_one, resp_one)
        expect(r).to be(true)
      end

      it "Different" do
        r = Watobo::Utils.compare_responses(resp_one, resp_two)
        expect(r).to be(false)
      end
  end
end

