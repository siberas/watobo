require 'spec_helper'

rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF

describe Watobo::Mixin::Shaper::Web10 do
  let(:request) { Watobo::Utils.text2request(rt) }
  context 'Query' do
    let(:new_query) { 'xxx' }

    it ".replaceQuery" do

      binding.pry
      request.replaceQuery new_query
      expect(request.url.to_s).to match(/xxx/)
    end

    it "test" do
      expect(request.url.to_s).to match(/bla/)
    end
  end
end

