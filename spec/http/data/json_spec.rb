require 'spec_helper'

# Coverage for lib/watobo/http/data/json.rb. Exercises JSON body parsing
# (via Watobo::Request wired by application/json content-type) and the
# eval-based value setter that round-trips updates back into the body.

describe Watobo::HTTPData::Json do
  def make_request(body, content_type: 'application/json')
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
    it "extracts a flat object as name/value pairs" do
      req = make_request('{"a":"1","b":"two","c":3}')
      params = req.parameters(:json)

      names_to_values = params.map { |p| [p.name, p.value] }.to_h
      expect(names_to_values).to eq(
        "['a']" => "1",
        "['b']" => "two",
        "['c']" => 3,
      )
    end

    it "descends into nested objects with bracketed paths" do
      req = make_request('{"outer":{"inner":"v"}}')
      names = req.parameters(:json).map(&:name)

      expect(names).to include("['outer']")           # container itself
      expect(names).to include("['outer']['inner']")  # leaf
    end

    it "descends into arrays with numeric indexes" do
      req = make_request('{"items":["x","y","z"]}')
      names = req.parameters(:json).map(&:name)

      expect(names).to include("['items']")
      expect(names).to include("['items'][0]")
      expect(names).to include("['items'][2]")
    end

    it "records a value's type via the :type field" do
      req = make_request('{"s":"txt","i":42,"b":true,"n":null}')
      types = req.parameters(:json).map { |p| [p.name, p.type] }.to_h

      expect(types["['s']"]).to eq(:STRING)
      expect(types["['i']"]).to eq(:INTEGER)
      expect(types["['b']"]).to eq(:TRUECLASS)
      expect(types["['n']"]).to eq(:NILCLASS)
    end

    it "returns [] for invalid JSON without raising" do
      req = make_request('{not valid json')
      expect(req.parameters(:json)).to eq([])
    end

    it "returns [] when the content type is not JSON" do
      req = make_request('{"x":1}', content_type: 'text/plain')
      expect(req.parameters(:json)).to eq([])
    end

    it "gives each parameter a stable md5 id derived from its path" do
      req = make_request('{"a":1,"b":2}')
      params = req.parameters(:json)

      # Same id across two parses of the same body → the setter can rely on it.
      params2 = req.parameters(:json)
      expect(params.map(&:id)).to eq(params2.map(&:id))

      # ids are content-addressed, not positional.
      req2 = make_request('{"b":2,"a":1}')
      by_name  = params.to_h { |p| [p.name, p.id] }
      by_name2 = req2.parameters(:json).to_h { |p| [p.name, p.id] }
      expect(by_name["['a']"]).to eq(by_name2["['a']"])
    end
  end

  context "set" do
    it "updates a top-level string value and rewrites the body" do
      req = make_request('{"tok":"old","other":"keep"}')
      tok = req.parameters(:json).find { |p| p.name == "['tok']" }
      tok.value = 'NEW'
      req.set(tok)

      body = JSON.parse(req.body)
      expect(body).to eq('tok' => 'NEW', 'other' => 'keep')
    end

    it "updates a nested value without disturbing siblings" do
      req = make_request('{"outer":{"a":"old","b":"keep"}}')
      inner = req.parameters(:json).find { |p| p.name == "['outer']['a']" }
      inner.value = 'NEW'
      req.set(inner)

      body = JSON.parse(req.body)
      expect(body).to eq('outer' => { 'a' => 'NEW', 'b' => 'keep' })
    end

    it "updates an array element by index" do
      req = make_request('{"xs":["a","b","c"]}')
      target = req.parameters(:json).find { |p| p.name == "['xs'][1]" }
      target.value = 'B'
      req.set(target)

      body = JSON.parse(req.body)
      expect(body).to eq('xs' => %w[a B c])
    end
  end
end
