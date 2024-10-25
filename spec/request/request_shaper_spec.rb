require 'spec_helper'

rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF

describe Watobo::Mixin::Shaper::Web10 do

  context 'Query' do
    let(:new_query) { 'xxx' }
    let(:request) { Watobo::Utils.text2request(rt) }

    it ".replaceQuery" do
      request.replaceQuery new_query
      expect(request.url.to_s).to match(/xxx/)
    end

    it ".replaceFileExt" do
      request.replaceFileExt("this")
      r = request.first.match?(/this.* HTTP\/1.1\r\n$/)
      expect(r).to eq(true)
    end

    it ".appendDir" do
      request.appendDir('appended')
      r = request.first.match?(/appended\/ HTTP\/1.1\r\n$/)
      expect(r).to eq(true)
    end

    it ".set_path" do
      request.set_path('/this/path')
      expect(request.path).to eq('/this/path')
      expect(request.first).to match(/\r\n$/)
    end

    it ".removeURI" do
      uri = request.removeURI
      expect(uri).to eq( "https://no.existing.host/")
      #binding.pry
      expect(request.first).to match(/ \/fkpsep\/service\?query=bla HTTP\/1.1\r\n/)
    end

    it ".restoreURI" do
      uri = request.removeURI
      request.restoreURI(uri)
      expect(request.first).to match(/ https:\/\/no.existing.host\/fkpsep\/service\?query=bla HTTP\/1.1\r\n/)
    end


  end
end

