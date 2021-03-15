#!/usr/bin/ruby
# rspec --format documentation ./spec/response_spec.rb
require 'devenv'
require 'watobo'

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

body = <<EOF
0A
AAAAAAAAAA
0
EOF

a = []
headers.each_line do |l|
  a << l
end
a << "\r\n"
a << body


describe Watobo::Response do
  context "unchunk" do

    it "check server header" do
      #  puts simple.url
      response = Watobo::Response.new a
      response.unchunk!

      # binding.pry
      expect(response.headers('Server').length).to eq(1)
    end

    it "check content-length" do
      #  puts simple.url
      response = Watobo::Response.new a
      response.unchunk!

      clen = response.headers('Content-Length').first.split(':')[1].strip.to_i
      expect(clen).to eq(10)
    end
  end
end

