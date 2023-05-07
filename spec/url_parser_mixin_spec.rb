require 'spec_helper'

describe Watobo::Request do
  let(:get_request_sample) {
    <<EOF
POST https://no.existing.host/my/path/to/here.php?q=where HTTP/1.1
Host: no.existing.host
User-Agent: Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:79.0) Gecko/20100101 Firefox/79.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Content-Type: multipart/form-data; boundary=---------------------------5543245338999447031528066707
Content-Length: 0
Upgrade-Insecure-Requests: 1
Connection: close
Cookie: SameSite=Strict; __cSrFtOkEn__=750524519E1888DE6BE2670492FA890350083A9F3866F3A827051FE87A5D5E61A16107B4F57DD5A2394934796999E7CAA8DCDDF92544AAAFF57A290258AAD0994932E99CDEC73C3FDC6C09943DC6C423; JSESSIONID=000097KvW1yrnOwThHRas7pgDIS:95fe5675-c2ac-49d1-8600-15aaab167e96
EOF
  }

  context "URL Mixin" do

    let(:request) { Watobo::Utils.text2request(get_request_sample) }
    let(:request_with_extension) { Watobo::Request.new('http://1.2.3.4/another/path/.zip')}

    it ".short" do
      expect(request.short).to eq('https://no.existing.host/my/path/to/here.php')
    end

    it ".path" do
      # binding.pry
      expect(request.path).to eq('/my/path/to/here.php')
    end

    it ".dir" do
      expect(request.dir).to eq('/my/path/to')
    end

    it ".query" do
      expect(request.query).to eq('q=where')
    end

    it '.site' do
      expect(request.site).to eq('no.existing.host:443')
    end

    it '.subdirs' do
      subdirs = request.subdirs
      expect(subdirs.length).to be(3)
      ["/my", "/my/path", "/my/path/to"].each do |dir|
        expect(subdirs.include?(dir)).to be(true)
      end

    end

    it '.file' do
      expect(request.file).to eq('here.php')
    end

    it '.file_ext' do
      expect(request.file_ext).to eq('here.php?q=where')
    end

  end

end
