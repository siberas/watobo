# rspec --format documentation ./spec/response_spec.rb
require 'devenv'
require 'watobo'



describe Watobo::Request do
  context "replaceFileExt" do

    it "simple" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.replaceFileExt('xxx')
      puts request.url
      str = request.to_s
      expect(str).to include('www.Domain-with_allowED_ch4rz.de/xxx')
    end

    it 'URI with path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de/path/to/file'
      puts request.url
      request.replaceFileExt('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de/path/to/xxx')

    end

    it 'URI with port and path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file'
      request.replaceFileExt('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/path/to/xxx')
    end

    it 'URI with port, path and query' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file?x=y'
      request.replaceFileExt('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/path/to/xxx')
    end

  end

  context 'Set Path' do
    it "simple" do
      #  puts simple.url
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de'
      request.set_path('xxx')
      puts request.url
      str = request.to_s
      expect(str).to include('www.Domain-with_allowED_ch4rz.de/xxx')
    end

    it 'URI with path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de/path/to/file'
      puts request.url
      request.set_path('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de/xxx')

    end

    it 'URI with port and path' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file'
      request.set_path('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/xxx')
    end

    it 'URI with port, path and query' do
      request = Watobo::Request.new 'http://www.Domain-with_allowED_ch4rz.de:8080/path/to/file?x=y'
      request.set_path('xxx')
      puts request.url
      expect(request.to_s).to include('www.Domain-with_allowED_ch4rz.de:8080/xxx')
    end
  end
end
