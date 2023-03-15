require 'spec_helper'


describe Watobo::Scanner::HostupCheck do

  let(:checker_direct){ Watobo::Scanner::HostupCheck.new(
    max_parallel_checks: 1,
    open_timeout: 1
  )}

  it "non existing" do
    uris = [ 'https://100.100.1.10', 'http://100.100.1.99' ].map{|u| URI.parse(u) }
    results = checker_direct.get_alive_sites(uris)
    expect(results.length).to be(1)
    expect(results.first).to eq("https://100.100.1.10")
  end

end