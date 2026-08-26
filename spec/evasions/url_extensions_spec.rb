require 'spec_helper'

rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF

describe Watobo::EvasionHandlers::UrlExtensions do
  let(:request) { Watobo::Utils.text2request(rt) }
  let(:evasion) { Watobo::EvasionHandlers::UrlExtensions.new }
  it ".run yields evaded path variants" do
    requests = []
    evasion.run(request) do |r|
      requests << r
    end

    expect(requests).not_to be_empty
    paths = requests.map(&:path)
    expect(paths).to include('/./fkpsep/./service')
    expect(paths).to include('/;/fkpsep;/service')
  end
end

