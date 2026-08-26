require 'spec_helper'

# Coverage for lib/watobo/http/data/multipart.rb.
#
# Note on the parameter model: Watobo exposes each multipart section as a set
# of parameters keyed by (index, name[, sub_name]). The section's body content
# is surfaced as a synthetic parameter named "_multipart_body_"; the form-field
# name is a sub-parameter of the Content-Disposition header. So changing "the
# value of the field named 'username'" means locating the right section and
# updating that section's "_multipart_body_", not looking up by field name.

describe Watobo::HTTPData::Multipart do
  BOUNDARY = '----WatoboTestBoundary'.freeze

  # Build a Request with a multipart body. Uses LF-only in the heredoc; the
  # Request normalizes to CRLF internally.
  def make_request(*section_texts)
    sections = section_texts.map { |t| "--#{BOUNDARY}\n#{t}" }.join("\n")
    raw = <<~REQ
      POST https://no.existing.host/upload HTTP/1.1
      Host: no.existing.host
      Content-Type: multipart/form-data; boundary=#{BOUNDARY}
      Content-Length: 999

      #{sections}
      --#{BOUNDARY}--
    REQ
    Watobo::Request.new(raw)
  end

  context "parameters" do
    it "surfaces a section's body under the synthetic name _multipart_body_" do
      req = make_request(%(Content-Disposition: form-data; name="username"\n\nalice))
      body_param = req.parameters(:multipart).find { |p| p.name == '_multipart_body_' }
      expect(body_param).not_to be_nil
      expect(body_param.value).to eq('alice')
    end

    it "exposes the form-field name as a Content-Disposition sub-parameter" do
      req = make_request(%(Content-Disposition: form-data; name="username"\n\nalice))
      field_name = req.parameters(:multipart)
                      .find { |p| p.name == 'Content-Disposition' && p.sub_name == 'name' }
      expect(field_name).not_to be_nil
      expect(field_name.value).to eq('username')
    end

    it "exposes filename as a Content-Disposition sub-parameter" do
      req = make_request(
        %(Content-Disposition: form-data; name="file"; filename="photo.jpg"\nContent-Type: image/jpeg\n\n<binary>)
      )
      filename = req.parameters(:multipart)
                    .find { |p| p.sub_name == 'filename' }
      expect(filename).not_to be_nil
      expect(filename.value).to eq('photo.jpg')
    end

    it "walks all sections and stamps their index onto each parameter" do
      req = make_request(
        %(Content-Disposition: form-data; name="a"\n\none),
        %(Content-Disposition: form-data; name="b"\n\ntwo),
      )
      body_params = req.parameters(:multipart).select { |p| p.name == '_multipart_body_' }
      by_index = body_params.map { |p| [p.index, p.value] }.to_h
      expect(by_index).to eq(0 => 'one', 1 => 'two')
    end
  end

  context "set" do
    it "updates a section's body and rewrites the request body" do
      req = make_request(%(Content-Disposition: form-data; name="username"\n\nalice))
      body_param = req.parameters(:multipart).find { |p| p.name == '_multipart_body_' }
      body_param.value = 'bob'
      req.set(body_param)

      expect(req.body).to include('bob')
      expect(req.body).not_to include('alice')
    end

    it "updates a filename sub-parameter and rewrites the request body" do
      req = make_request(
        %(Content-Disposition: form-data; name="file"; filename="photo.jpg"\nContent-Type: image/jpeg\n\n<binary>)
      )
      filename = req.parameters(:multipart).find { |p| p.sub_name == 'filename' }
      filename.value = 'evil.php'
      req.set(filename)

      expect(req.body).to include('filename="evil.php"')
      expect(req.body).not_to include('photo.jpg')
    end
  end

  it "raises on construction when Content-Type is not multipart" do
    raw = <<~REQ
      POST https://no.existing.host/api HTTP/1.1
      Host: no.existing.host
      Content-Type: text/plain
      Content-Length: 0

    REQ
    req = Watobo::Request.new(raw)
    expect { Watobo::HTTPData::Multipart.new(req) }
      .to raise_error(RuntimeError, /Wrong Content-Type/)
  end
end
