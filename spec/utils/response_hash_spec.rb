require 'spec_helper'

describe Watobo::Utils do

  let(:request) { Watobo::Request.new 'http://www.mydomain.de/to/go.php' }

  let(:response_headers) {
    <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Content-Length: 0
EOF
  }

  let(:body_one) {
    <<EOF
This is an example for a custom file not found.
end of text
EOF
  }

  let(:body_with_timestamp_de) {
    <<EOF
This is an example for a custom file not found.
01.01.1970
end of text 11:20:22
EOF
  }

  let(:html_with_timestamp_de) {
    <<EOF
<html>
<h1>This is an example for a custom file not found.</h1>
<p>01.01.1970
end of text </p>11:20:22
EOF
  }

  let(:response_base) { Watobo::Response.new(response_headers.lines.map(&:chomp)) }

  let(:response_one) { response_base << "\r\n" << body_one}


  let(:baseline_hash){ Watobo::Utils.responseHash(request, response_one)}
  context "response hash" do

    it "text with timestamps" do
      response_with_timestamp_de = ( response_base << "\r\n" << body_with_timestamp_de )
      hash = Watobo::Utils.responseHash(request, response_with_timestamp_de )
      expect(baseline_hash).to eq(hash)
    end

    it "html with timestamps" do
      response = ( response_base << "\r\n" << html_with_timestamp_de )
      hash = Watobo::Utils.responseHash(request, response )
      expect(baseline_hash).to eq(hash)
    end
  end
end