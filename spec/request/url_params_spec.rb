require 'spec_helper'

rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla&p2=gaga HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF

describe Watobo::HTTP::Url do

  context 'Maniulate URL Parameters' do
    let(:request) { Watobo::Utils.text2request(rt) }

    it ".parameters" do
      params = request.url.parameters
      expect(params.length).to eq(2)
    end

    it ".set" do
      params = request.url.parameters
      query_param = params.select { |p| p.name == 'query' }.first
      query_param.value = 'blubber'
      request.set query_param
      expect(request.first).to match(/query=blubber.* HTTP\/1.1\r\n/)
      params_after = request.url.parameters
      expect(params_after.length).to eq(2)
      query_param = params_after.select { |p| p.name == 'query' }.first
      expect(query_param.value).to eq('blubber')
    end
  end

  context "URL conversions" do
    let(:request) { Watobo::Utils.text2request(rt) }
    it ".to_uri - no flags" do
      uri = request.url.to_uri
      expect(uri.to_s).to eq("https://no.existing.host/fkpsep/service?query=bla&p2=gaga")
    end
  end
end
