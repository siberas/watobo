module Watobo
  module Transformers
    def self.to_multipart(request)
      mp = Watobo::Request.new request
      mp.setMethod("POST")
      # mp.remove_header("Content-Length")

      params = mp.parameters(:url, :wwwform)
      mp.clear_parameters(:url, :wwwform)

      boundary = '-' * 10 + Time.now.to_i.to_s
      mp.set_header("Content-Type", "multipart/form-data; boundary=#{boundary}")

      body = []
      params.each do |p|
        body << "--#{boundary}"
        body << "Content-Disposition: form-data; name=\"#{p.name}\""
        body << "Content-Type: application/x-www-form-urlencoded"
        body << ''
        body << p.value
      end
      body << "--#{boundary}--"

      mp.set_body(body.join("\r\n"))
      mp
    end
  end
end