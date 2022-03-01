# @private 
module Watobo #:nodoc: all
  module Mixins
    # This mixin can be used to parse a String or any object which supports method.to_s into a valid http request string
    module RequestParser
      # This method parses (eval) ruby code which is included in the string.
      # Ruby code is identified by its surrounding delimiters - default: '%%'.
      # For examples the string 'ABC%%"_"*10%%DEFG' will result to 'ABC__________DEFG'
      #
      # Possible prefs:
      #
      # :code_dlmtr [String] - set ruby code delimiter
      #
      # returns nil on parse error

      def parse_code(prefs = {})
        cprefs = {:code_dlmtr => '%%'} # default delimiter for ruby code
        cprefs.update(prefs)

        #pattern="(#{cprefs[:code_dlmtr]}.*?#{cprefs[:code_dlmtr]})"
        pattern = cprefs[:code_dlmtr]
        request = self.to_s
        expression = ""

        begin
          # puts new_request
          expr = ''

          pos = 0
          off = 0
          match = []
          code_marks = []
          while pos >= 0 and pos < request.length
            code_offset = request.index(pattern, pos)

            unless code_offset.nil?
              new_line_index = request.index("\n", pos)
              unless new_line_index.nil?
                if new_line_index < code_offset
                  # new_request << request[match[0]..code_offset-1] unless match.empty?
                  match = []
                  # pos = code_offset
                end
              end
              match << code_offset

              if match.length == 2
                code_marks << match.dup
                match = []
              end
              pos = code_offset + pattern.length
            else
              break
            end
          end

          new_request = ''
          unless code_marks.empty?
            code_marks.each_with_index do |cm, i|
              #puts cm.to_yaml
              last = i > 0 ? (code_marks[i - 1][1] + pattern.length) : 0
              new_request << request[last..cm[0] - 1] if cm[0] > 0
              exp_start = cm[0] + pattern.length
              exp_end = cm[1] - 1

              expression = request[exp_start..exp_end]
              expression.strip!
              next if expression.empty?
              puts "DEBUG: executing: #{expression}" if $DEBUG
              #result = expression.empty? ? "" : eval("#{expression}")
              result = eval(expression)
              puts "DEBUG: got #{result.class}" if $DEBUG
              if result.is_a? File
                data = result.read
                result.close
              elsif result.is_a? String
                data = result
              elsif result.is_a? Array
                data = result.join
              else
                puts "!!!WATOBO - expression must return String or File !!!"
              end
              new_request << data
            end
            new_request << request[code_marks.last[1] + pattern.length..-1] unless code_marks.last[1] >= request.length - 1

          else
            new_request = request
          end

          return new_request

        rescue SyntaxError, LocalJumpError, NameError => e
          #  raise SyntaxError, "SyntaxError in '#{expression}'"
          puts e
          puts e.backtrace

        end
        return nil
      end


      def to_request(opts = {})
        options = {:update_content_length => false}
        options.update opts

        begin
          text = parse_code

          # remove all CR, because we only want LF ('\n')
          # DON'T!!!!
          # we will loos CRLF added by Code-Injections
          #text.gsub!(/\r/,'')

          # parse erb templating
          parser = ERB.new text
          text = parser.result(binding)

          return nil if text.nil?
          request = []

          # find end of headers (eoh)
          # test for \r\n\r\n and \n\n
          # the pattern with the lower index will be taken
          eoh = nil
          nn_index = text.index("\n\n")
          rnrn_index = text.index("\r\n\r\n")
          if nn_index && rnrn_index
            eoh = nn_index < rnrn_index ? nn_index : rnrn_index
          elsif nn_index
            eoh = nn_index
          elsif rnrn_index
            eoh = rnrn_index
          end

          unless eoh.nil?
            header = text.slice(0, eoh).split("\n").map { |h| "#{h.strip}\r\n" }
            #body = text.slice(eoh + 2, text.length - 1)
            body = text[eoh + 2..-1]
          else
            header = text.split(/\n/).map { |h| "#{h.strip}\r\n" }
            body = nil
          end

          request.concat header

          #Watobo::Request.create request
          request = Watobo::Request.new(request)

          ct = request.content_type_ex

          # last line is without "\r\n" if text has a body
          if ct =~ /multipart/i and body then
            #Content-Type: multipart/form-data; boundary=---------------------------3035221901842
            if ct =~ /boundary=([\-\w]+)/
              boundary = $1.strip
              chunks = body.split(/--#{boundary}[\-]{0,2}[\r\n]{0,2}/)
              #chunks.pop # remove "--"
              #puts "Multipart request has #{chunks.length} chunks"
              new_body = []
              chunks.each do |c|
                new_chunk = ''
                #c.gsub!(/[\-]+$/,'')
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
              body << new_body.join("--#{boundary}\r\n")
              body << "--#{boundary}--\r\n"
            end
            #  body.gsub!(/\n/, "\r\n") if body

          end

          unless body.nil?
            request.push "\r\n"
            # don't strip body! Some requests need a CRLF at the end, e.g. Response Smuggling
            request.push body #.strip
          end

          request.fixupContentLength() if options[:update_content_length] == true
          return request
        rescue => bang
          puts bang
          puts bang.backtrace
          raise bang
        end
        #return nil
      end

      def to_response(opts = {})
        options = {:update_content_length => false}
        options.update opts
        begin
          text = parse_code
          result = []

          if text =~ /\n\n/
            dummy = text.split(/\n\n/)
            header = dummy.shift.split(/\n/)
            body = dummy.join("\n\n")
          else
            header = text.split(/\n/)
            body = nil
          end

          header.each do |h|
            result.push "#{h}\r\n"
          end


          #Watobo::Response.create result
          result = Watobo::Response.new(result)

          if body then
            result.push "\r\n"
            result.push body.strip
          end

          result.fixupContentLength() if options[:update_content_length] == true
          puts ">>"
          puts result
          return result
        rescue => bang
          puts bang
          puts bang.backtrace
          raise bang
        end
        #return nil
      end


      def to_request_UNUSED(opts = {})
        options = {:update_content_length => false}
        options.update opts
        begin
          text = parse_code
          result = []

          if text =~ /\n\n/
            dummy = text.split(/\n\n/)
            header = dummy.shift.split(/\n/)
            body = dummy.join("\n\n")
          else
            header = text.split(/\n/)
            body = nil
          end

          header.each do |h|
            result.push "#{h}\r\n"
          end

          # result.extend Watobo::Mixin::Parser::Url
          # result.extend Watobo::Mixin::Parser::Web10
          # result.extend Watobo::Mixin::Shaper::Web10
          #Watobo::Request.create result
          result = Watobo::Request.new(result)

          ct = result.content_type
          # last line is without "\r\n" if text has a body
          if ct =~ /multipart\/form/ and body then
            #Content-Type: multipart/form-data; boundary=---------------------------3035221901842
            if ct =~ /boundary=([\-\w]+)/
              boundary = $1.strip
              chunks = body.split(boundary)
              e = chunks.pop # remove "--"
              new_body = []
              chunks.each do |c|
                new_chunk = ''
                c.gsub!(/[\-]+$/, '')
                next if c.nil?
                next if c.strip.empty?
                c.strip!
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

          result.fixupContentLength() if options[:update_content_length] == true
          return result
        rescue
          raise
        end
        #return nil
      end

    end
  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "lib"))
  $: << inc_path

  require 'watobo'

  text = <<'EOF'
%%"GET"%% http://www.siberas.de/ HTTP/1.1
Content-Type: text/html
%%"x"*10%%Vary: Accept-Encoding
Expires: Thu, 19 Jul 2012 06:57:20 GMT
Cache-Control: max-age=0, no-cache, no-store
Pragma: no-cache
Date: Thu, 19 Jul 2012 06:57:20 GMT
Content-Length: 203
Connection: close%%"XXXX"%%

<html><%= ( 3 * 3 ).to_s %></html>
EOF

  text.strip!
  puts text
  puts
  puts "==="
  puts
  text.extend Watobo::Mixins::RequestParser
  puts text.to_request
  Watobo::Utils.hexprint text
end
