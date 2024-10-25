require 'spec_helper'

describe Watobo::Modules::Active::Sqlinjection::Sqli_timing do


    # let(:request){ instance_double(Watobo::Request)}
    let(:request) { Watobo::Request.new("http://www.siberas.de") }
    # let(:test_session){ instance_double(Watobo::Net::Http::Session)}
    let(:session) { Watobo::Net::Http::Session.new('rspec') }
    let(:sender) { Watobo::Net::Http::Sender.new(update_otts: true) }
    let(:ott_cache) {}
    let(:response) { s = <<EOF
HTTP/1.1 200 OK
Host: 100.100.1.20
Date: Sun, 12 Feb 2023 12:10:29 GMT
Connection: close
X-Powered-By: PHP/7.4.3
Content-Type: text/html; charset=UTF-8
Cache-Control: no-cache, private
Date: Sun, 12 Feb 2023 12:10:29 GMT
Content-Length: 3584

<html lang="en">
HOWDY!
</html>
EOF
    Watobo::Utils.string2response(s)
    }

    let(:response_header) {
      r =<<EOF
HTTP/1.1 200 OK
Host: 100.100.1.20
Date: Sun, 12 Feb 2023 12:10:29 GMT
Connection: close
X-Powered-By: PHP/7.4.3
Content-Type: text/html; charset=UTF-8
Cache-Control: no-cache, private
Date: Sun, 12 Feb 2023 12:10:29 GMT
Content-Length: 10
EOF
      Watobo::Response.new(r.lines.map(&:strip).map{|l| l + "\r\n"})
    }

    let(:response_body) {
      <<EOF
<html lang="en">
HOWDY!
</html>
EOF
    }

    let(:request) {
      rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF
      Watobo::Request.new rt
    }

    let(:xml_request) {
      rt = <<EOF
POST https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
Content-Type: application/xml; charset=utf-8

<?xml version="1.0" encoding="UTF-8"?>
<config-auth client="vpn" type="auth-reply" aggregate-auth-version="2"><version who="vpn">v9.12</version><device-id>linux-64</device-id><capabilities><auth-method>single-sign-on-v2</auth-method><auth-method>single-sign-on-external-browser</auth-method></capabilities><opaque is-for="sg">
<tunnel-group>wwww</tunnel-group>
<auth-method>single-sign-on-v2</auth-method>
<config-hash>1725529728852</config-hash>
</opaque><auth><username>xxxxxxx</username><password>xxxxxx</password></auth></config-auth>
EOF
      Watobo::Request.new rt
    }

    let(:chat) { Watobo::Chat.new(request, response) }
    let(:xml_chat) { Watobo::Chat.new(xml_request, response) }

    let(:check) { Watobo::Modules::Active::Sqlinjection::Sqli_timing.new('rpsec') }

    before do
      #allow(Watobo::Net::Http::Sender).to receive(:new).and_return(sender)

      #allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:exec).and_call_original
    end

    context "generateChecks" do

    it ".generateChecks" do
      collection = []

      # expect(sender).to receive(:exec).and_wrap_original
      #  allow(test_session).to receive(:doRequest).and_return('AAA', 'BBB')
      # allow(sender).to receive(:read_body).and_return(response_with_token)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:connect).and_return(nil)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:unzip!).and_return(nil)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:close_socket).and_return(nil)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:send_request).and_return(nil)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:read_header).and_return(response_header)
      allow_any_instance_of(Watobo::Net::Http::Sender).to receive(:read_body).and_return(response)

      allow_any_instance_of(Watobo::Modules::Active::Sqlinjection::Sqli_timing).to receive(:doRequest).and_after_calling_original{| response| collection << response }

      checks = []
      check.generateChecks(xml_chat){|check|
        checks << check
      }
      results = checks.map(&:call)
      binding.pry

    end
  end
end
