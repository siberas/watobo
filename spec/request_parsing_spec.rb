require 'spec_helper'

rt = <<EOF
POST https://no.existing.host HTTP/1.1
Host: no.existing.host
User-Agent: Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:79.0) Gecko/20100101 Firefox/79.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Content-Type: multipart/form-data; boundary=---------------------------5543245338999447031528066707
Content-Length: 0
Upgrade-Insecure-Requests: 1
Connection: close
Cookie: SameSite=Strict; __cSrFtOkEn__=750524519E1888DE6BE2670492FA890350083A9F3866F3A827051FE87A5D5E61A16107B4F57DD5A2394934796999E7CAA8DCDDF92544AAAFF57A290258AAD0994932E99CDEC73C3FDC6C09943DC6C423; JSESSIONID=000097KvW1yrnOwThHRas7pgDIS:95fe5675-c2ac-49d1-8600-15aaab167e96

-----------------------------5543245338999447031528066707
Content-Disposition: form-data; name="importFile"; filename="file.tld"
Content-Type: application/octet-stream

line1
line2
line3
-----------------------------5543245338999447031528066707
Content-Disposition: form-data; name="returnToUrl"


-----------------------------5543245338999447031528066707
Content-Disposition: form-data; name="AQSN"


-----------------------------5543245338999447031528066707
Content-Disposition: form-data; name="applQueueSchemaTitle"

Queues
-----------------------------5543245338999447031528066707--
EOF

mpr=<<EOS
POST https://performancemanager5.successfactors.eu:443/odata/v2/restricted/ONB2WhatToBringActivity,ONB2WhatToBringConfig,ONB2WhatToBringItemConfig/$batch HTTP/1.1
Host: performancemanager5.successfactors.eu
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:83.0) Gecko/20100101 Firefox/83.0
Accept: multipart/mixed
Accept-Language: en-US
Referer: https://performancemanager5.successfactors.eu/sf/start?_s.crb=KL0DfqiKsuUfpIQjD8pb0jmOmo6tdTpgRs4evKxUG8A%253d
sap-contextid-accept: header
DataServiceVersion: 2.0
MaxDataServiceVersion: 2.0
sap-cancel-on-close: true
Content-Type: multipart/mixed;boundary=batch_d117-9084-d69b
OPTR_CXT: 01000500014502f2bb-a4e2-4933-9c2b-e72023b23f2829820909-1501-babe-face-000000000003befe62df-ab52-4552-bf23-a5ef23f46027HTTP    ;
X-Subaction: 1
X-Event-ID: EVENT-UNKNOWN-UNKNOWN-urb6500088-20220224143326-129414-3
X-Ajax-Token: KL0DfqiKsuUfpIQjD8pb0jmOmo6tdTpgRs4evKxUG8A%3d
X-SAP-Page-Info: companyId=xxxxT3&moduleId=HOME&pageId=HOME_TAB&pageQualifier=HOME_V3&uiVersion=V12&userId=124
Content-Length: 540
Origin: https://performancemanager5.successfactors.eu
Cookie: bizxCompanyId=xxxxT3; route=bc85789f28b05122883fdeafe04fd0144a17b18d; JSESSIONID=71F7FDE8DEFD5E892E1F4FBD50340AF0.vsa7611199; oiosaml-fragment=; zsessionid=c394f068-9a4e-4c65-bd7d-225828ff1afb; bizxThemeId=3pspt10gf7; %2Flogin-markFromServer=true
Sec-Fetch-Dest: empty
Sec-Fetch-Mode: cors
Sec-Fetch-Site: same-origin
Connection: close


--batch_d117-9084-d69b
Content-Type: application/http
Content-Transfer-Encoding: binary

GET ONB2WhatToBringActivity?$select=supplementalInformation%2C%20whatToBringConfigNav%2FwhatToBringItemsConfig%2Ftitle_localized&$expand=whatToBringConfigNav%2FwhatToBringItemsConfig&$filter=process%20eq%20%27E562D4DCC2F44054B948B92402C57D39%27 HTTP/1.1
sap-cancel-on-close: true
sap-contextid-accept: header
Accept: application/json
Accept-Language: en-US
DataServiceVersion: 2.0
MaxDataServiceVersion: 2.0


--batch_d117-9084-d69b--
EOS

request = Watobo::Utils.text2request(rt)
multipart_request = mpr.extend Watobo::Mixins::RequestParser

describe Watobo::Request do
  context "URL Mixin" do


    it "str" do
      url = request.url.to_s
      expect(url).to eq('https://no.existing.host')

    end

  end

  context "Cookie Parsing" do
    it "cookie count" do
      expect(request.cookies.to_a.count).to eq(3)
    end

  end

  context "Multipart" do
    #binding.pry
  end
end
