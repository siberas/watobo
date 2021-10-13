# @private 
module Watobo #:nodoc: all
  module Utils
    def Utils.text2request(text)
      result = []
      return result if text.strip.empty?
      # UTF-8 CleanUp
      text = text.unpack("C*").pack("C*")

      eoh = nil
      body_sep = ''
      ["\n\n", "\r\n\r\n"].each do |bs|
        next unless eoh.nil?
        body_sep = bs
        eoh = text.index(body_sep)
      end

      unless eoh.nil?
        header = text.slice(0, eoh).split("\n").map {|h| "#{h.strip}\r\n"}
        body = text.slice(eoh + body_sep.length, text.length - 1)
      else
        header = text.split(/\n/).map {|h| "#{h}\r\n"}
        body = nil
      end

      result.concat header

      result = Watobo::Request.new result

      ct = result.content_type

      # last line is without "\r\n" if text has a body
      if ct =~ /multipart/ and body then
        #Content-Type: multipart/form-data; boundary=---------------------------3035221901842
        if ct =~ /boundary=([\-\w]+)/
          boundary = $1.strip
          # chunks = body.split(boundary)
          chunks = body.split(/--#{boundary}[\-]{0,2}[\r\n]{0,2}/)
          #e = chunks.pop # remove "--"
          new_body = []
          chunks.each do |c|
            new_chunk = ''
            #c.gsub!(/[\-]+$/, '')
            next if c.nil?
            next if c.strip.empty?
            #c.strip!
            if c =~ /\n\n/
              ctmp = c.split(/\n\n/)
              cheader = ctmp.shift.split(/\n/)
              cbody = ctmp.join("\n\n")
            else
              cheader = c.split(/\n/)
              cbody = nil
            end
            new_chunk = cheader.join("\r\n")
            new_chunk += "\r\n\r\n"
            new_chunk += cbody.strip + "\r\n" if cbody

            # puts cbody
            new_body.push new_chunk

          end
          body = "--#{boundary}\r\n"
          body += new_body.join("--#{boundary}\r\n")
          body += "--#{boundary}--"
        end
        #  body.gsub!(/\n/, "\r\n") if body

      end

      if body then
        result.push "\r\n"
        result.push body.strip
      end


      return result

    end
  end
end

if __FILE__ == $0
  # TODO Generated stub
end
