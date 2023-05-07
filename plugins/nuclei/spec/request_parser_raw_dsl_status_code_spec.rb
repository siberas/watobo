require 'spec_helper'

sample_file = File.basename(__FILE__).gsub('request_parser_', '').gsub(/_spec.*/, '.yaml')
file = File.expand_path(File.join(File.dirname(__FILE__), '..', 'samples', sample_file))



describe Watobo::Plugin::NucleiScanner::NucleiCheck do
  context "parse raw_dsl_status_code" do
    # base = Watobo::Request.new 'https://www.acme.de'
    # requests = raw_with_multipart.send(:nuclei_requests, base)
    #

    it 'check number of requests' do
      nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})
      nr = nuclei_check.requests.length
      expect(nr).to eq(2)
    end


    it 'check path of first request' do
      nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})
      baseline = Watobo::Request.new 'http://a.b.c/apath/'

      nr = nuclei_check.requests.first
      request = nr.generate(baseline).first
      expect(request.path).to eq('apath/jars/upload')
    end

    it 'check path of second request' do
      nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})
      baseline = Watobo::Request.new 'http://a.b.c/apath/'

      nr = nuclei_check.requests.last
      request = nr.generate(baseline).first
      expect(request.method).to eq('GET')
      expect(request.path).to eq('apath/jobmanager/logs/..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252f..%252ftmp%252fpoc')
    end

    it 'check url' do
      nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})
      baseline = Watobo::Request.new 'http://a.b.c/apath/'

      nr = nuclei_check.requests.first
      request = nr.generate(baseline).first
      expect(request.url.to_s).to eq('http://a.b.c/apath/jars/upload')
    end

    it 'check host header' do
      nuclei_check = Watobo::Plugin::NucleiScanner::NucleiCheck.new(0, file, {})
      baseline = Watobo::Request.new 'http://a.b.c/apath/'

      nr = nuclei_check.requests.first
      request = nr.generate(baseline).first
      h, host = request.headers('Host').first.split(':').map{|x| x.strip}

      expect(host).to eq(baseline.host)
    end
  end
end
