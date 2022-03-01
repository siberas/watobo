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


describe Watobo::Request do
    it "parse URL" do
      request = Watobo::Utils.text2request(rt)
      expect(request.url.to_s).to eq('https://no.existing.host/fkpsep/service')
    end

    it "counts parameters" do
      request = Watobo::Utils.text2request(rt)
      expect(request.parameters.to_a.count).to eq(15)
    end

end
