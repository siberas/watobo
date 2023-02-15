require 'spec_helper'

describe Watobo::Net::Http::Session do
  let(:session) { Watobo::Net::Http::Session.new('rspec', update_sids: true) }

  it '.doRequest with session' do
    request = Watobo::Request.new("http://localhost:6666")
    req, resp = session.doRequest request
    expect(resp.body).to match /hello watobo/i

    request = Watobo::Request.new("http://localhost:6666/foo")
    req, resp = session.doRequest request
    binding.pry
  end
end