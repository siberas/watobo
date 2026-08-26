require 'spec_helper'

# Coverage for lib/watobo/parser/html.rb. The parser is `extend`ed onto
# a Response when the Content-Type matches /(html|text)/, so we drive it
# through Watobo::Response rather than instantiating classes directly.

describe Watobo::Parser::HTML do
  def html_response(body)
    Watobo::Utils.string2response(<<~RESP)
      HTTP/1.1 200 OK
      Content-Type: text/html; charset=utf-8
      Content-Length: #{body.bytesize}

      #{body}
    RESP
  end

  describe "input_fields" do
    it "extracts fields across every form in the document" do
      resp = html_response(<<~HTML)
        <html><body>
          <form action="/login">
            <input name="user" value="alice"/>
            <input name="pass" type="password" value=""/>
          </form>
          <form action="/search">
            <input name="q" value="cats"/>
          </form>
        </body></html>
      HTML

      fields = resp.input_fields
      names_to_values = fields.map { |f| [f.name, f.value] }.to_h
      expect(names_to_values).to eq(
        'user' => 'alice',
        'pass' => '',
        'q'    => 'cats',
      )
    end

    it "returns empty [] on an html body with no forms" do
      resp = html_response('<html><body><p>no forms</p></body></html>')
      expect(resp.input_fields).to eq([])
    end

    it "yields each field to a block if given" do
      resp = html_response(<<~HTML)
        <html><body>
          <form><input name="a" value="1"/><input name="b" value="2"/></form>
        </body></html>
      HTML

      yielded = []
      resp.input_fields { |f| yielded << f.name }
      expect(yielded).to eq(%w[a b])
    end

    it "defaults missing id/name/value attributes to empty string, not nil" do
      resp = html_response('<html><body><form><input/></form></body></html>')
      field = resp.input_fields.first
      expect(field.name).to eq('')
      expect(field.value).to eq('')
      expect(field.id).to eq('')
    end

    it "converts a field to a Watobo::WWWFormParameter" do
      resp = html_response(<<~HTML)
        <html><body><form>
          <input name="csrf" value="TOKEN"/>
        </form></body></html>
      HTML

      field = resp.input_fields.first
      parm = field.to_www_form_parm
      expect(parm).to be_a(Watobo::WWWFormParameter)
      expect(parm.name).to eq('csrf')
      expect(parm.value).to eq('TOKEN')
    end

    it "converts a field to a Watobo::UrlParameter" do
      resp = html_response(<<~HTML)
        <html><body><form>
          <input name="q" value="term"/>
        </form></body></html>
      HTML

      field = resp.input_fields.first
      parm = field.to_url_parm
      expect(parm).to be_a(Watobo::UrlParameter)
      expect(parm.name).to eq('q')
      expect(parm.value).to eq('term')
    end
  end

  describe "forms" do
    it "yields each form to the given block" do
      resp = html_response(<<~HTML)
        <html><body>
          <form id="a"><input name="x" value="1"/></form>
          <form id="b"><input name="y" value="2"/></form>
        </body></html>
      HTML

      count = 0
      resp.forms { |_f| count += 1 }
      expect(count).to eq(2)
    end
  end
end
