require 'spec_helper'

class EvasionDummy
  include Watobo::Evasions

  def run(request, &block)
    binding.pry
  end
end

rt = <<EOF
GET https://no.existing.host/fkpsep/service?query=bla HTTP/1.1
Content-Type: application/apl.universal.ui.v1+json
Accept: application/apl.universal.ui.v1+json
Host: no.existing.host
EOF

describe Watobo::EvasionHandlers::HTTPVersion do
  let(:dummy) { EvasionDummy.new }
  let(:request) { Watobo::Utils.text2request(rt) }

  context Watobo::EvasionHandlers::SlashSlash do

    let(:evasion) { Watobo::EvasionHandlers::SlashSlash.new }

    it ".run" do
      requests = []

      dummy.run(request)

    end
  end
end

