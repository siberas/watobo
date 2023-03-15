require 'spec_helper'

describe Watobo::Utils do
  context "string2response" do
    let(:response_text) {
      <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
Content-Length: 0

my body with SPECIAL_CHARS and ÄÜÖ
EOF
    }

    let(:response_text_without_body){
      <<EOF
HTTP/1.1 200 OK
Date: Fri, 05 Feb 2021 10:58:21 GMT
Server: Apache
EOF
    }

    let(:response_text_with_bad_chars){ response_text.gsub(/SPECIAL_CHARS/, "\x02\x03\xff end").force_encoding('UTF-8')}

    it "check response body" do
      response = Watobo::Utils.string2response(response_text)
      expect(response.body).to match(/my body/)
    end

    it "check response with bad chars" do
      response = Watobo::Utils.string2response(response_text_with_bad_chars)
      expect(response.body).to match(/my body/)
    end

    it "check response without body" do
      response = Watobo::Utils.string2response(response_text_without_body)
      expect(response.body).to be(nil)
    end
  end
end