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

describe Watobo::EvasionHandlers do
  let(:dummy) { EvasionDummy.new }
  let(:request) { Watobo::Utils.text2request(rt) }

  context Watobo::EvasionHandlers do
    it '.evasion_handlers for HTTPVersion and HTTPHeaders' do
    selection = dummy.evasion_handlers(['HTTPVersion','HTTPHeaders'])
    expect(selection.length).to be(2)
    end

  end

  context Watobo::EvasionHandlers::SlashSlash do

    let(:evasion) { Watobo::EvasionHandlers::SlashSlash.new }

    it ".evasion_handlers" do
      requests = []

      dummy.evasion_handlers do |handler|
        #  binding.pry
      end

    end
  end
end

