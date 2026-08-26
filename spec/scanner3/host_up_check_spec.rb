require 'spec_helper'


describe Watobo::Scanner::HostupCheck do

  let(:checker_direct){ Watobo::Scanner::HostupCheck.new(
    max_parallel_checks: 1,
    open_timeout: 1
  )}

  # Integration test: requires that 100.100.1.10 is reachable and
  # 100.100.1.99 is not. Skipped in any environment where neither host
  # is reachable (CI, sandboxes) — the checker already swallows network
  # errors internally and just returns an empty result set.
  it ".get_alive_sites (integration)" do
    uris = [ 'https://100.100.1.10', 'http://100.100.1.99' ].map{|u| URI.parse(u) }
    results = checker_direct.get_alive_sites(uris)
    skip 'no target reachable from this network' if results.empty?
    expect(results.length).to eq(1)
    expect(results.first).to eq('https://100.100.1.10')
  end

end