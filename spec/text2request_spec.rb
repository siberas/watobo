#!/usr/bin/ruby
require 'devenv'
require 'watobo'

#
# After parsing, the Content-Length header should be the size 974
TEXT=<<EOF
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

request = Watobo::Utils.text2request(TEXT)
