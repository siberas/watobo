# @private 
module Watobo #:nodoc: all
  module Utils
    def self.string2response(text, opts = {})
      options = {
        update_content_length: false,
        charset: 'UTF-8'
      }
      options.update opts
      begin
        text.encode!(options[:charset], :invalid => :replace, :undef => :replace, :replace => '')
        eoh = text =~ /\r\n\r\n|\n\n/

        raw_header = eoh.nil? ? text : text[0..eoh - 1]
        raw_body = eoh.nil? ? nil : text[eoh..-1]
        raw_body.strip! if raw_body

        response = raw_header.lines.map{|l| "#{l.strip}\r\n"}

        if !raw_body.nil? && !raw_body.empty?
          response << "\r\n" << raw_body
        end
        # return response
        return Watobo::Response.new(response)

      rescue => bang
        puts bang
        puts bang.backtrace
      end
      return nil
    end
  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  $: << inc_path

  require 'watobo'

  text = <<'EOF'
HTTP/1.1 200 OK
Content-Type: text/html
Vary: Accept-Encoding
Expires: Thu, 19 Jul 2012 06:57:20 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache
Date: Thu, 19 Jul 2012 06:57:20 GMT
Content-Length: 203
Connection: close

<html></html>
EOF

  text2 = "HTTP/1.1 200 OK\r\n" +
    "Content-Type: text/html\r\n" +
    "Vary: Accept-Encoding\r\n" +
    "Expires: Thu, 19 Jul 2012 06:57:20 GMT\r\n" +
    "Cache-Control: max-age=0, no-cache, no-store\r\n" +
    "Pragma: no-cache\r\n" +
    "Date: Thu, 19 Jul 2012 06:57:20 GMT\r\n" +
    "Content-Length: 203\r\n" +
    "Connection: close\r\n\r\n" +
    "<html></html>\r\n"

  unless ARGV[0].nil?
    if File.exist? ARGV[0]
      text = File.open(ARGV[0], "rb").read
    end
  end
  r = Watobo::Utils.string2response text
  puts r.class
  puts r.status
  puts r.content_type
  puts r
  puts
  puts "="
  puts
  r = Watobo::Utils.string2response text2
  puts r.class
  puts r.status
  puts r.content_type
  puts r

end