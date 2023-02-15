require 'spec_helper'


describe Watobo::Net::Http::Session do
  context "replaceFileExt" do


    #let(:request){ instance_double(Watobo::Request)}
    let(:request){ Watobo::Request.new("http://www.siberas.de")}
    # let(:test_session){ instance_double(Watobo::Net::Http::Session)}
    let(:session) { Watobo::Net::Http::Session.new('rspec')}
    let(:sender){ Watobo::Net::Http::Sender.new( update_otts: true )}
    let(:ott_cache)
    let(:response_with_token){ s =<<EOF
HTTP/1.1 200 OK
Host: 100.100.1.20
Date: Sun, 12 Feb 2023 12:10:29 GMT
Connection: close
X-Powered-By: PHP/7.4.3
Content-Type: text/html; charset=UTF-8
Cache-Control: no-cache, private
Date: Sun, 12 Feb 2023 12:10:29 GMT
Set-Cookie: XSRF-TOKEN=NEW_OTT%3D; expires=Sun, 12-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; samesite=lax
Set-Cookie: laravel_session=NEW_LARAVEL_SESSION; expires=Sun, 12-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; httponly; samesite=lax
Content-Length: 3584

<html lang="en">
HOWDY!
</html>
EOF
    Watobo::Utils.string2response( s)
}


    before do
      allow(Watobo::Net::Http::Sender).to receive(:new).and_return(sender)
    end

    it "replace One-Time-Token" do

      #expect(sender).to receive(:exec).and_wrap_original
      #  allow(test_session).to receive(:doRequest).and_return('AAA', 'BBB')
      #allow(sender).to receive(:read_body).and_return(response_with_token)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:read_body).and_return(response_with_token)


      req, resp = session.doRequest(request)

      binding.pry

    end
  end
end
