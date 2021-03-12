# @private
module Watobo #:nodoc: all
  module Mixin
    module Shaper
      module Web10
        include Watobo::Constants

        URL_SPLIT = '(^[^ ]*) ([^:]*):\/\/([^\/:]*)(:\d*)?([^\?]*)(.*) (HTTP.*)'

        m, method, scheme, site, port, path, query = 'GET http://www.sib-er2_as.de/path/to/file?query=x HTTP/1.1'.match(/(^[^ ]*) ([^:]*):\/\/([^\/]*)(:\d*)?([^\?]*)(.*) (HTTP.*)/i).to_a

        def replace_post_parm(parm, value)
          parm_quoted = Regexp.quote(parm)
          self.last.gsub!(/([?&]{1}|^)#{parm_quoted}=([^&]*)(&{0,1})/i, "\\1#{parm}=#{value}\\3")
        end

        def replace_get_parm(parm, value)
          parm_quoted = Regexp.quote(parm)
          self.first.gsub!(/([?&]{1})#{parm_quoted}=([^ &]*)(&{0,1})/i, "\\1#{parm}=#{value}\\3")
        end

        def replaceMethod(new_method)
          self.first.gsub!(/^[^[:space:]]{1,}/i, "#{new_method}")
        end

        def replaceFileExt(new_file)
          begin
            file = new_file.strip
            file.gsub!(/^\//, "")
            m, method, scheme, site, port, path, query, version = self.first.match(/#{URL_SPLIT}/i).to_a
            unless m.nil?
              i = path.rindex('/')
              new_path = i.nil? ? '/' : path[0..i]
              new_path << new_file
              new_site = site + (port.nil? ? '' : port)
              self.first.gsub!(/#{Regexp.quote(new_site)}(.*)/, "#{new_site}#{new_path} #{version}")
              return true
            end
          rescue => bang
            puts bang
          end
          return false
        end


        def replaceElement(new_element)
          new_element.gsub!(/^\//, "")
          self.first.gsub!(/([^\?]*\/)(.*) (HTTP.*)/i, "\\1#{new_element} \\3")
        end

        def replaceURL(new_url)
          self.first.gsub!(/(^[^[:space:]]{1,}) (.*) (HTTP.*)/i, "\\1 #{new_url} \\3")
        end

        def replaceQuery(new_query)
          new_query.gsub!(/^\//, "")
          self.first.gsub!(/(.*\/)(.*) (HTTP.*)/i, "\\1#{new_query} \\3")
        end

        def strip_path()
          self.first.gsub!(/([^\?]*\/)(.*) (HTTP.*)/i, "\\1# \\3")
        end

        def setDir(dir)
          dir.strip!
          dir.gsub!(/^\/+/, "")
          dir.gsub!(/\/+$/, "")
          dir << '/' unless dir.empty?
          self.first.gsub!(/(^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)(.*)( HTTP\/.*)/, "\\1#{dir}\\3")
        end


        def set_path(path_name)
          begin
            new_path = path_name.strip
            new_path.gsub!(/^\//, "")
            m, method, scheme, site, port, path, query, version = self.first.match(/#{URL_SPLIT}/i).to_a
            unless m.nil?
              new_site = site + (port.nil? ? '' : port)
              self.first.gsub!(/#{Regexp.quote(new_site)}(.*)/, "#{new_site}/#{new_path} #{version}")
              return true
            end
          rescue => bang
            puts bang
          end
          return false
        end

        #
        # set a new file extension, e.g. mysite.html to mysite.php
        # if no extension nor a file is given, the new extension will only be appended
        # note: the first leading dot will be removed 
        # possible preferences are:
        #   :keep_query    =>  keeps query parameters
        #   default-set is empty
        def set_file_extension(nxt, *prefs)
          return self.first if nxt.nil?
          nxt.gsub!(/^\./, '')
          s = "#{self.first}"
          fend = nil
          pend = nil

          pstart = s.index('?')
          pend = s.rindex(/ HTTP\//)

          fend = (pstart - 1) unless pstart.nil?
          fend = (pend - 1) if fend.nil?

          return self.first if fend.nil?

          fstart = s.rindex('/', fend)
          unless s[fstart - 1] == '/'
            fstart += 1 unless fstart.nil?
          else
            fstart = fend
          end

          fname = s[fstart..fend]
          fname.gsub!(/\..*/, '')
          fname << ".#{nxt}"

          ns = s[0..fstart - 1]
          ns << fname

          if prefs.include? :keep_query
            unless pstart.nil?
              ns << s[pstart..pend]
            end
          end

          ns << s[pend..-1]

          self.first.replace ns
        end

        def appendDir(dir)
          dir.strip!
          dir.gsub!(/^\//, "")
          dir << "/" unless dir =~ /\/$/
          self.first.gsub!(/(^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}.*\/).*( HTTP\/.*)/, "\\1#{dir}\\2")

        end

        def add_post_parm(parm, value)
          unless self.has_body?
            # if we don't have a body we have to create one
            line = ''
            self.push "\r\n"
          else
            line = self.pop
          end
          line << '&' unless line.empty?
          line << "#{parm}=#{value}"

          self.push line
        end

        def add_get_parm(parm, value)
          line = self.shift
          new_p = "&"
          new_p = "?" unless line =~ /\?/
          new_p += parm
          line.gsub!(/( HTTP\/.*)/, "#{new_p}=#{value}\\1")
          self.unshift(line)
        end

        alias :add_url_parm :add_get_parm

        def addHeader(header, value)
          self_copy = []
          self_copy.concat(self.headers)
          self_copy.push "#{header}: #{value}\r\n"

          unless self.body.nil?
            self_copy.push "\r\n"
            #self_copy.concat(self.body)
            self_copy.push self.body
          end

          self.replace(self_copy)

        end

        alias_method :add_header, :addHeader

        def removeURI
          if self.first =~ /(^[^[:space:]]{1,}) (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/ then
            uri = $2
            self.first.gsub!(/(^[^[:space:]]{1,}) (#{Regexp.quote(uri)})/, "\\1 /")
            # puts "* Removed URI: #{uri}"
            # puts self.first
            return uri
          else
            return nil
          end
          #self.first.gsub!(/^(.*)(https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/,"\\1/")
        end

        def removeBody
          self.pop if self[-2].strip.empty?
        end

        def set_body(content)
          if self[-2].strip.empty?
            self.pop
          else
            self << "\r\n"
          end
          self << content
        end

        def rewrite_body(pattern, content)
          if self.has_body?
            puts "rewrite_body ... #{pattern} - #{content}"

            b = self.pop.force_encoding('BINARY')
            #puts "Body Encoding: #{b.encoding}"
            #puts "Pattern Encoding: #{pattern.encoding}"


            b.gsub!(/#{pattern}/i, content)

            self << b

            puts self.to_s
            return true
          end
          false
        end

        def restoreURI(uri)
          if self.first =~ /(^[^[:space:]]{1,}) \/(.*) (HTTP\/.*)/ then
            method = $1
            rest = $2
            http = $3.strip
            #self.first.gsub!(/^\w*/, "#{method} #{uri}#{rest}")
            self.shift
            self.unshift "#{method} #{uri}#{rest} #{http}\r\n"
            return self.first
          else
            return nil
          end
          #self.first.gsub!(/^(.*)(https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/,"\\1/")
        end

        #
        # R E M O V E _ H E A D E R
        #

        def removeHeader(header)
          begin

            while i = headers.index { |h| h =~ /#{header}/i }
              self.delete_at i
            end

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            puts self
            puts "====="
          end
        end

        alias_method :remove_header, :removeHeader

        # removeUrlParms
        # Function: Remove all parameter within the URL
        #
        def removeUrlParms
          line = self.shift
          return false if line.nil?
          new_line = "#{line}"
          # get end-of-path-index
          eop_index = line.rindex(/[^ HTTP]\//)
          # get start of parms
          sop_index = line.index(/(\?|&)/, eop_index)
          # find end-of-url
          eou_index = line.index(/ HTTP/)

          unless sop_index.nil? or eou_index.nil?
            new_line = line[0..sop_index - 1]
            new_line += line[eou_index..-1]
          end

          self.unshift new_line
        end

        def removeCookies
          begin
            pattern = '^Cookie'
            while i = headers.index { |h| h =~ /#{pattern}/i }
              #puts "* remove #{self[i]}"
              self.delete_at i
            end
          rescue => bang
            puts bang
            if $DEBUG
              puts bang.backtrace
              puts self
            end
          end

        end

        def removeHeader_OLD(header)
          #  p "REMOVE HEADER: #{header}"
          begin
            self_copy = []
            eoh = false
            self.each do |line|
              puts self if line.nil?
              if not eoh == true then
                if not line =~ /#{header}/i
                  self_copy.push line unless line.nil?
                end
              else
                self_copy.push line unless line.nil?
              end

              if line and line.strip.empty? then
                eoh = true
              end
            end
            self.replace(self_copy)

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            puts self
            puts "====="
          end
        end

        def replace_header(header, value)

        end

        def fix_session(pattern, value)

        end

        def fix_content_length
          return false if self.body.nil?
          # had trouble with length calculation of binary data in multipart request          
          blen = self.body.force_encoding("ASCII-8BIT").length
          set_header("Content-Length", blen)
        end

        def fixupContentLength_UNUSED
          te = self.transferEncoding
          if te == TE_CHUNKED then
            # puts "Transfer-Encoding = TE_CHUNKED"
            # puts self.body
            self.removeHeader("Transfer-Encoding")
            self.addHeader("Content-Length", "0")
            new_r = []
            new_r.concat self.headers
            new_r.push "\r\n"

            bytes_to_read = 0
            body = []
            is_new_chunk = false

            off = 0
            new_body = ''

            body_orig = self.body
            puts body_orig.class
            while body_orig[off..-1] =~ /^([0-9a-fA-F]{1,6})\r\n/
              len_raw = "#{$1}"

              len = len_raw.hex

              chunk_start = off + len_raw.length + 2
              chunk_end = chunk_start + len

              break if len == 0

              new_body.chomp!
              new_body += "#{body_orig[chunk_start..chunk_end]}"

              off = chunk_end + 2
            end

            new_r.push new_body
            self.replace(new_r)
            self.fix_content_length
            # puts "= FIXED ="
            # puts self.headers
          elsif te == TE_NONE then
            self.fix_content_length
          end

        end

        def fixupContentLength
          self.unchunk
          self.fix_content_length
        end

        def setRawQueryParms(parm_string)
          return nil if parm_string.nil?
          return nil if parm_string == ''
          new_r = ""
          path = Regexp.quote(self.path)
          #puts path
          if self.first =~ /(.*#{path})/ then
            new_r = $1 << "?" << parm_string
          end
          self.first.gsub!(/(.*) (HTTP\/.*)/, "#{new_r} \\2")
        end

        def appendQueryParms(parms)
          return if parms.nil?
          return if parms == ''

          puts self.first
          puts self.file_ext

          pref = (self.file_ext =~ /\?/) ? '&' : '?'
          puts "append query parms"
          self.first.gsub!(/(.*) (HTTP\/.*)/, "\\1#{pref}#{parms} \\2")

        end

        def set_content_length(length)
          set_header("Content-Length", length)
        end

        def set_content_type(ctype)
          set_header("Content-Type", ctype)
        end

        def set_header(header, value)
          begin
            new_header = "#{header}: #{value}\r\n"
            self.each_with_index do |h, i|
              if h =~ /^#{Regexp.quote(header)}:/i
                self[i] = new_header
                return true
              end

              if h.strip.empty? or i == self.length - 1
                self.insert(i, new_header)
                return true
              end
            end
          rescue => bang
            puts bang
          end
          return false
        end

        alias :setHeader :set_header

        # sets post data
        def setData(data)
          return if data.nil?
          if self.has_body?
            self.pop
            self.push data
          else
            self.push("\r\n")
            self.push data
          end
        end

        alias :setBody :setData

        def setMethod(method)
          m = method.is_a?(Symbol) ? method.to_s.upcase : method
          self.first.gsub!(/(^[^[:space:]]{1,}) /, "#{m} ")
        end

        alias_method :set_method, :setMethod
        alias :method= :setMethod

        def setHTTPVersion(version)
          self.first.gsub!(/HTTP\/(.*)$/, "HTTP\/#{version}")
          #  puts "HTTPVersion fixed: #{self.first}"
        end

      end

      module HttpResponse
        include Watobo::Constants

        def unchunk!
          return false unless self.has_body?

          unchunked = self.unchunk
          self.replace(unchunked)
          self.fix_content_length

        end

        def unchunk
          return Response.new(self) unless self.has_body?

          if self.transfer_encoding == TE_CHUNKED then
            self.removeHeader("Transfer-Encoding")
            self.addHeader("Content-Length", "0")
            new_r = []
            new_r.concat self.headers
            new_r.push "\r\n"

            bytes_to_read = 20
            body = []
            is_new_chunk = false

            off = 0
            new_body = ''

            body_orig = self.body
            pattern = '[0-9a-fA-F]+\r?\n'
            while off >= 0 and off < body_orig.length
              chunk_pos = body_orig.index(/(#{pattern})/, off)
              len_raw = $1
              unless chunk_pos.nil?
                len = len_raw.strip.hex

                chunk_start = chunk_pos + len_raw.length
                chunk_end = chunk_start + len

                break if len == 0
                chunk = "#{body_orig[chunk_start..chunk_end]}"
                new_body += chunk.chomp
                off = chunk_end
              end
            end
            new_r.push new_body
            return Watobo::Response.new new_r

          end
          return Response.new(self)
        end

        def unzip!
          if self.content_encoding == TE_GZIP or self.transfer_encoding == TE_GZIP
            if self.has_body?
              unziped = self.unzip_body

              self[-1] = unziped
              self.removeHeader("Transfer-Encoding") if self.transfer_encoding == TE_GZIP
              self.removeHeader("Content-Encoding") if self.content_encoding == TE_GZIP
              self.fix_content_length
            end
          end

        end

        def unzip
          if self.content_encoding == TE_GZIP or self.transfer_encoding == TE_GZIP
            if self.has_body?
              unzipped = Response.new(self)
              unzipped.unzip!
              return unzipped
            end
          end

          return Response.new(self)
        end

        def unzip_body
          begin
            if self.has_body?
              gziped = self.last
              gz = Zlib::GzipReader.new(StringIO.new(gziped))
              data = gz.read
              return data
            end

          rescue => bang
            puts bang
          end

        end

      end
    end
  end
end
