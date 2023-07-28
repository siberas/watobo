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
  it ".run" do
    requests = []
    evasion.run(request) do |r|
      requests << r
    end

    paths = requests.map{|r| r.path_ext }
    r = paths.select{|p| p =~ /\/\/fkpsep\/\/service.*query=bla/ }
    binding.pry

  end
end

