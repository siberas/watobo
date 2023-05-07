# rspec --format documentation ./spec/response_spec.rb
#require 'devenv'
#require 'watobo'
require 'spec_helper'


describe Watobo::Request do
  context "replaceFileExt" do

    it "simple" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.replaceFileExt('xxx')
      str = request.url.to_s
      expect(str).to include('www.Domain-with_allowED_ch4rz.de/xxx')
    end

    it 'URI with path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de/path/to/file'
      request.replaceFileExt('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de/path/to/xxx')

    end

    it 'URI with port and path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file'
      request.replaceFileExt('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/path/to/xxx')
    end

    it 'URI with port and path and trailing slash' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file/'
      request.replaceFileExt('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/path/to/file/xxx')
    end

    it 'URI with port, path and query' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file?x=y'
      request.replaceFileExt('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/path/to/xxx')
    end

  end

  context 'Set Path' do
    it "simple" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.set_path('xxx')
      str = request.url.to_s
      expect(str).to include('www.Domain-with_allowED_ch4rz.de/xxx')
    end

    it 'URI with path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de/path/to/file'
      request.set_path('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de/xxx')

    end

    it 'URI with port and path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file'
      request.set_path('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/xxx')
    end

    it 'URI with port, path and query' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file?x=y'
      request.set_path('xxx')
      expect(request.url.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/xxx')
    end
  end

  context 'Set Header' do
    it "Set header without value" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.set_header "X-Atlassian-token: no-check"
      h, v = request.headers('Atlassian').first.split(':')
      expect(h.strip).to eq('X-Atlassian-token')
      expect(v.strip).to eq('no-check')
    end

    it "Set header with value" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.set_header "X-Atlassian-token", "no-check"
      h, v = request.headers('Atlassian').first.split(':')
      expect(h.strip).to eq('X-Atlassian-token')
      expect(v.strip).to eq('no-check')
    end
  end

  context 'Add Header' do
    it "Add header without value" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.add_header "X-Atlassian-token: first"
      request.add_header "X-Atlassian-token: second"
      expect(request.headers('Atlassian').length).to eq(2)
      h, v = request.headers('Atlassian').first.split(':')
      expect(h.strip).to eq('X-Atlassian-token')
      expect(v.strip).to eq('first')
    end

    it "Add header with value" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.add_header "X-Atlassian-token", "first"
      request.add_header "X-Atlassian-token", "second"
      expect(request.headers('Atlassian').length).to eq(2)
      h, v = request.headers('Atlassian').last.split(':')
      expect(h.strip).to eq('X-Atlassian-token')
      expect(v.strip).to eq('second')
    end

  end
end
