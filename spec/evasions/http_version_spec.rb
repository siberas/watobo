require 'spec_helper'

rt = <<EOF
PUT https://no.existing.host/fkpsep/service HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
User-Agent: PostmanRuntime/7.28.4
Host: no.existing.host
Content-Length: 384
Cookie: SESSION=b3b4f247-354e-4e6a-9053-00be75ae7088

{
  "payload": {
    "anwendung": "APP",
    "version": "2.0.0",
    "kundenId": "K0213342",
    "teilnehmerId": "F0211928",
    "blz": "94059421",
    "bic": "TESTDETT421",
    "pushToken": "xyz",
    "pushAktiv": "JA",
    "publicKeyBank": "ewogICJwdWJsaWNLZXlCYW5rViI6ImFiY2RlZiIsCiAgInB1YmxpY0tleUJhbmtBIjoiYWJjZGVmIgp9",
    "schluesselstatus": "INITIALISIERT"
  }
}
EOF

describe Watobo::EvasionHandlers::HTTPVersion do
  let(:request) { Watobo::Utils.text2request(rt) }
  let(:evasion) { Watobo::EvasionHandlers::HTTPVersion.new }
  it ".run" do


    requests = []
    evasion.run(request) do |r|
      requests << r
    end
    num_evasions =  Watobo::EvasionHandlers::HTTPVersion::INJECTIONS.length
    expect(requests.length).to be(num_evasions)
    versions = requests.map{|r| r.http_version }
    Watobo::EvasionHandlers::HTTPVersion::INJECTIONS.each do |e|
      expect(versions.include?(e)).to be(true)
    end
  end
end

