require 'spec_helper'

describe Watobo::Modules::Passive::Cookie_options do
  let(:request_one) { Watobo::Request.new("http://www.siberas.de") }
  let(:request_two) { Watobo::Request.new("http://www.siberas.de/path/new") }
  let(:response_one) { s = <<EOF
HTTP/1.1 200 OK
Host: 100.100.1.20
Date: Sun, 12 Feb 2023 12:10:29 GMT
Connection: close
X-Powered-By: PHP/7.4.3
Content-Type: text/html; charset=UTF-8
Cache-Control: no-cache, private
Date: Sun, 12 Feb 2023 12:10:29 GMT
Set-Cookie: XSRF-TOKEN=NEW_OTT%3D; expires=Sun, 12-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; samesite=lax
Set-Cookie: laravel_session=NEW_LARAVEL_SESSION; expires=Sun, 12-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; samesite=lax
Content-Length: 3584

<html lang="en">
Response One
</html>
EOF
  Watobo::Utils.string2response(s)
  }

  let(:response_two) { s = <<EOF
HTTP/1.1 200 OK
Host: 100.100.1.20
Date: Sun, 12 Feb 2023 12:10:29 GMT
Connection: close
X-Powered-By: PHP/7.4.3
Content-Type: text/html; charset=UTF-8
Cache-Control: no-cache, private
Date: Sun, 12 Feb 2023 12:10:29 GMT
Set-Cookie: XSRF-TOKEN=NEW_OTT%3D; expires=Sun, 22-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; samesite=lax
Set-Cookie: laravel_session=NEW_LARAVEL_SESSION; expires=Sun, 12-Feb-2023 14:10:29 GMT; Max-Age=7200; path=/; samesite=lax
Content-Length: 100

<html lang="en">
Response Two
</html>
EOF
  Watobo::Utils.string2response(s)
  }
  let(:check) { Watobo::Modules::Passive::Cookie_options.new('rspec') }
  let(:chat_one) { Watobo::Chat.new(request_one, response_one) }
  let(:chat_two) { Watobo::Chat.new(request_two, response_two) }

  before do
    # we hook DataStore.add_finding method because we don't have an active
    # datastore connected.
    allow(Watobo::DataStore).to receive(:add_finding).and_return(nil)
  end

  context "unique detection" do
    it "detect xsrf token" do
      check.do_test(chat_one)
      check.do_test(chat_two)
      #binding.pry
      expect(Watobo::Findings.length).to be(4)


      uniques = []
      Watobo::Findings.each do |f|
        uniques << f.details[:unique]
      end
      xsrfs = uniques.select{|e| e =~ /xsrf\-token/i }
      laravels = uniques.select{|e| e =~ /laravel_session/i }

      expect(xsrfs.length).to be(2)
      expect(laravels.length).to be(2)
    end
  end
end

