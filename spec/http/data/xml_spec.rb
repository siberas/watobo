require 'spec_helper'

# Coverage for lib/watobo/http/data/xml.rb. Exercises Nokogiri-based XML
# body parsing (via Watobo::Request wired by application/xml content-type)
# and the CSS-selector-driven value setter.

describe Watobo::HTTPData::Xml do
  def make_request(body, content_type: 'application/xml')
    raw = <<~REQ
      POST https://no.existing.host/api HTTP/1.1
      Host: no.existing.host
      Content-Type: #{content_type}
      Content-Length: #{body.bytesize}

      #{body}
    REQ
    Watobo::Request.new(raw)
  end

  context "parameters" do
    it "extracts leaf text nodes as name/value pairs" do
      req = make_request(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <root>
          <name>alice</name>
          <age>42</age>
        </root>
      XML

      by_name = req.parameters(:xml).map { |p| [p.name, p.value] }.to_h
      expect(by_name['name']).to eq('alice')
      expect(by_name['age']).to eq('42')
    end

    it "records each leaf's parent element name" do
      req = make_request(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <root>
          <user>
            <name>alice</name>
          </user>
        </root>
      XML

      name_param = req.parameters(:xml).find { |p| p.name == 'name' }
      expect(name_param.parent).to eq('user')
    end

    it "returns [] when the content type is not XML" do
      req = make_request('<root><a>x</a></root>', content_type: 'text/plain')
      expect(req.parameters(:xml)).to eq([])
    end

    it "returns [] for an empty body" do
      raw = <<~REQ
        POST https://no.existing.host/api HTTP/1.1
        Host: no.existing.host
        Content-Type: application/xml
        Content-Length: 0

      REQ
      req = Watobo::Request.new(raw)
      expect(req.parameters(:xml)).to eq([])
    end

    it "tolerates malformed XML without raising" do
      req = make_request('<root><unclosed>')
      expect { req.parameters(:xml) }.not_to raise_error
    end
  end

  context "set" do
    it "updates a leaf text value and rewrites the body" do
      req = make_request(<<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <root>
          <name>alice</name>
        </root>
      XML

      target = req.parameters(:xml).find { |p| p.name == 'name' }
      target.value = 'bob'
      req.set(target)

      expect(req.body).to match(/<name>bob<\/name>/)
      expect(req.body).not_to match(/alice/)
    end
  end
end
