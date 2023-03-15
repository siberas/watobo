# http://www.ietf.org/rfc/rfc2396.txt
# http://en.wikipedia.org/wiki/URI_scheme
# URI = scheme:[//authority]path[?query][#fragment]
#
# http://www.mysite.com:80/my/path/show.php?p=aaa&debug=true
#
# .proto = "http"
# .host = "www.mysite.com"
# .site = "www.mysite.com:80"
# .dir = "/my/path"
# .file = "show.php"
# .file_ext = "show.php?p=aaa&debug=true"
# .path = "/my/path/show.php"
# .query = "p=aaa&debug=true"
# .fext = "php"
# .path_ext => "/my/path/show.php?p=aaa&debug=true"
# .short => "http://www.mysite.com:80/my/path/show.php"
# .origin => "http://www.mysite.com:80"
# .subdirs => ['/my','/my/path']

# @private
module Watobo #:nodoc: all
  module Mixin
    module Parser

      #  module Parameters
      #  def each(prefs, &block)

      # end
      # end

      module Url
        include Watobo::Constants

        def short
          uri = URI.parse(url_string)
          return File.join(uri.origin, uri.path) if uri.origin
          nil
        end

        def origin
          uri = URI.parse(url_string)
          uri.origin
        end



        def file
          #@file ||= nil
          # return @file unless @file.nil?
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}[^\?]*\/(.*) HTTP.*/
            tmp = $1
            end_of_file_index = tmp.index(/\?/)

            if end_of_file_index.nil?
              @file = tmp
            elsif end_of_file_index == 0
              @file = ""
            else
              @file = tmp[0..end_of_file_index - 1]
            end

          else
            @file = ""
          end
        end

        def file_ext
          #@file_ext ||= nil
          # return @file_ext unless @file_ext.nil?
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}[^\?]*\/(.*) HTTP.*/
            @file_ext = $1
          else
            @file_ext = ''
          end
        end

        # returns a string containing all urlparms
        # e.g. "parm1=first&parm2=second"
        def urlparms
          return '' if self.first.nil?
          begin
            off = self.first.index('?')
            return nil if off.nil?
            eop = self.first.index(' HTTP/')
            return nil if eop.nil?
            parms = self.first[off + 1..eop - 1]
            return parms
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return ''
        end

        def method
          if self.first =~ /(^[^[:space:]]{1,}) /i then
            return $1
          else
            return nil
          end
        end

        def method_get?
          return false if method.nil?
          return true if method =~ /^get$/i
          return false
        end

        def method_post?
          return false if method.nil?
          return true if method =~ /^post$/i
          return false
        end

        # The path may consist of a sequence of path segments separated by a
        # single slash "/" character.  Within a path segment, the characters
        #"/", ";", "=", and "?" are reserved.  Each path segment may include a
        # sequence of parameters, indicated by the semicolon ";" character.
        # The parameters are not significant to the parsing of relative
        # references.

        #
        # http://www.mysite.com:80/my/path/show.php?p=aaa&debug=true
        # path = "/my/path/show.php"
        def path
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/([^\?]*).* HTTP/i then
            return "/#{$1}"
          else
            return "/"
          end
        end

        # path_ext = "my/path/show.php?p=aaa&debug=true"
        def path_ext
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/(.*) HTTP\//i then
            return "/#{$1}"
          else
            return ""
          end
        end

        def dir
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/([^\?]*)\/.* HTTP/i then
            return "/#{$1}"
          else
            return ""
          end
        end

        def query
          begin
            q = nil
            if self.first =~ /^[^[:space:]]{1,} (.*) HTTP.*/ then
              uri = $1
            end
            off = uri.index('?')
            # parts.shift
            # puts "HTTPParser.query: #{parts.join('?')}"
            return "" if off.nil?
            return uri[off + 1..-1]
          rescue => bang
            puts "!!! Could not parse query !!!"
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return ''

        end

        def element
          cl = self.first.gsub(/\?+/, "?")
          cl.gsub!(/ HTTP.*/, '')
          dummy = cl.split('?').first
          if dummy =~ /^[^[:space:]]{1,} ([a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}).*\/(.*)/i then
            return $2
          else
            return ""
          end
        end

        def doctype
          # /.*\/.*?\.(\w{2,4})(\?| )/.match(self.first)
          /\.(\w{2,4})/.match(self.file)

          return $1 unless $1.nil?
          return ''
        end

        def proto
          proto = "unknown"
          if self.first =~ /^[^[:space:]]{1,} ([a-zA-Z]+):\/\//i
            proto = $1
          end
          proto
        end

        def is_ssl?
          return true if self.first =~ /^[^[:space:]]{1,} https/i
          return false
        end

        def is_chunked?
          self.each do |h|
            return true if h =~ /^Transfer-Encoding.*chunked/i
            break if h.strip.empty?
          end
          return false
        end

        def url_string
          url = ''
          # return @url unless @url.nil?
          if self.first =~ /^[^[:space:]]{1,} ([a-zA-Z]+:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}.*) HTTP\//i then
            url = $1
          end
          url
        end

        #  alias :url :url_string

        def site
          #@site ||= nil
          # return @site unless @site.nil?
          if self.first =~ /^[^[:space:]]{1,} ([a-zA-Z]+):\/\/([\-0-9a-zA-Z.]*)([:0-9]{0,6})/i then
            host = $2
            port_extension = $3
            proto = $1
            s = host + port_extension
            if port_extension == ''
              s = host + ":" + DEFAULT_PORT_HTTPS.to_s if proto =~ /^https$/i
              s = host + ":" + DEFAULT_PORT_HTTP.to_s if proto =~ /^http$/i
            end
            @site = s
          else
            @site = nil
          end
          @site
        end

        def host
          #@host ||= nil
          # return @host unless @host.nil?
          # if self.first =~ /^[^[:space:]]{1,} https?:\/\/([\-0-9a-zA-Z.]*)[:0-9]{0,6}/i then
          if self.first =~ /^[^[:space:]]{1,} [a-zA-Z]+:\/\/([\-0-9a-zA-Z.]*)[:0-9]{0,6}/i then
            @host = $1
          else
            @host = ''
          end
          @host
        end

        # returns all subdir combinations
        # www.company.com/this/is/my/path.php
        # returns:
        # [ "/this", "/this/is", "/this/is/my" ]
        def subDirs
          subs = self.dir.split(/\//)

          combinations = []
          subs.each_with_index do |_, index|
            next if index == 0
            combinations << subs[0..index].join('/')
          end

          combinations
        end
        alias :subdirs :subDirs

        def port
          return nil if self.first.nil?
          dummy = self.first
          portnum = nil
          parts = dummy.split('?')

          if parts[0] =~ /^[^[:space:]]{1,} https:\/\//i then
            portnum = 443
          elsif parts[0] =~ /^[^[:space:]]{1,} http:\/\//i
            portnum = 80
          end
          if parts[0] =~ /^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*:([0-9]{0,6})/i then
            portnum = $1
          end
          return portnum
        end

        # get_parms returns an array of parm=value
        def get_parms
          return [] if self.first.nil?
          begin
            off = self.first.index('?')
            return [] if off.nil?
            eop = self.first.index(' HTTP/')
            return [] if eop.nil?
            parms = self.first[off + 1..eop - 1].split('&').select { |x| x =~ /=/ }
            #   puts parms
            return parms
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
          return []
          # parmlist=[]
          # if self.first =~ /^[^[:space:]]{1,} (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}).*\/.*(\?.*=.*) HTTP/i then
          #  dummy = $2.gsub!(/\?+/,"?").split('?')
          # remove left part of ? from url
          #  dummy.shift

          #  parmlist=dummy.join.split(/\&/)
          # end
          # return parmlist

        end

        #################### doubles

        def get_parm_names(&block)

          parm_names = []
          parmlist = []
          parmlist.concat(get_parms)

          parmlist.each do |p|
            if p then
              p.gsub!(/=.*/, '')
              yield p if block_given?
              parm_names.push p
            end
          end

          return parm_names

        end

        def get_parm_value(parm_name)
          parm_value = ""
          self.get_parms.each do |parm|
            if parm =~ /^#{Regexp.quote(parm_name)}=/i then
              dummy = parm.split(/=/)
              if dummy.length > 1 then
                #  parm_value=dummy[1].gsub(/^[ ]*/,"")
                parm_value = dummy[1].strip
              end
            end
          end
          return parm_value
        end

        def post_parm_value(parm_name)
          parm_value = ""
          self.post_parms.each do |parm|
            if parm =~ /#{Regexp.quote(parm_name)}/i then
              dummy = parm.split(/=/)
              if dummy.length > 1 then
                parm_value = dummy[1].strip
              else
                # puts "Uhhhh ... need parameter value from '#{parm}''"
              end
            end
          end
          return parm_value
        end

      end

      module Web10
        include Watobo::Constants

        def post_parms
          parmlist = []
          return parmlist unless has_body?
          parms = self.last.force_encoding('ASCII-8BIT')
          begin
            if parms =~ /\=.*\&?/i
              parmlist = parms.split(/\&/)
              parmlist.map! { |p| x = p.strip.empty? ? nil : p }
              parmlist.compact!
            end
          rescue => bang
            # puts self.last.unpack("C*").pack("C*").gsub(/[^[:print:]]/,".")
            if $DEBUG
              puts bang
              puts bang.backtrace

            end
          end
          return parmlist
        end

        def parms
          parmlist = []
          parmlist.concat(get_parms)
          parmlist.concat(post_parms)

          return parmlist
        end

        def parm_names
          parm_names = []
          parmlist = []
          parmlist.concat(get_parms)
          parmlist.concat(post_parms)
          parmlist.each do |p|
            p.gsub!(/=.*/, '')
            parm_names.push p
          end

          return parm_names

        end

        def post_parm_names(&block)

          parm_names = []
          parmlist = []

          parmlist.concat(post_parms)
          parmlist.each do |p|
            if p then
              p.gsub!(/=.*/, '')
              p.strip!
              yield p if block_given?
              parm_names << p
            end
          end

          return parm_names

        end

        def header_value(header_name)
          header_values = []
          self.headers.each do |header|
            begin
              if header =~ /^#{header_name}/i then
                vstart = header.index ':'
                unless vstart.nil?
                  header_values.push header[vstart + 1..-1].strip
                end
              end
            rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
            end
          end
          return header_values
        end

        def content_type(default_ct = 'undefined')
          ct = default_ct
          self.each do |line|
            begin
              break if line.strip.empty?
              # cl = line.encode('ASCII', :invalid => :replace, :undef => :replace)
              cl = line.force_encoding('ASCII-8BIT')
              if cl =~ /^Content-Type:([^;]*);?/i then
                ct = $1
                break
              end
            rescue => bang
              puts "! could not parse content_type !"
              puts bang
              puts cl
              #            puts cl.gsub(/[^[:print:]]/, '.')

            end
          end
          return ct.strip
        end

        def content_type_ex(default_ct = 'undefined')
          ct = default_ct
          self.each do |line|
            break if line.strip.empty?
            # cl = line.encode('ASCII', :invalid => :replace, :undef => :replace)
            cl = line.force_encoding('ASCII-8BIT')
            if cl =~ /^Content-Type:(.*)/i then
              ct = $1.strip
              break
            end
          end
          return ct.strip
        end

        def content_length
          # Note: Calculate Chunk-Encoded Content-Length
          # this is only possible if the whole body is loaded???
          ct = -1
          self.each do |line|
            break if line.strip.empty?
            if line =~ /^Content-Length:(.*)/i then
              ct = $1.strip.to_i
              break
            end
          end
          return ct
        end

        def content_encoding
          te = TE_NONE
          self.each do |line|
            break if line.strip.empty?
            if line =~ /^Content-Encoding:(.*)/i then
              dummy = $1.strip
              #  puts "Content-Encoding => #{dummy}"
              te = case dummy
                   when /chunked/i
                     TE_CHUNKED
                   when /compress/i
                     TE_COMPRESS
                   when /zip/i
                     TE_GZIP
                   when /deflate/i
                     TE_DEFLATE
                   when /identity/i
                     TE_IDENTITY
                   else
                     TE_NONE
                   end
              break
            end
          end
          return te
        end

        def transferEncoding
          te = TE_NONE
          self.each do |line|
            break if line.strip.empty?
            if line =~ /^Transfer-Encoding:(.*)/i then
              dummy = $1.strip
              # puts dummy
              te = case dummy
                   when /chunked/i
                     TE_CHUNKED
                   when /compress/i
                     TE_COMPRESS
                   when /zip/i
                     TE_GZIP
                   when /deflate/i
                     TE_DEFLATE
                   when /identity/i
                     TE_IDENTITY
                   else
                     TE_NONE
                   end
              break
            end
          end
          return te
        end

        alias :transfer_encoding :transferEncoding

        def contentMD5
          b = has_body? ? body : ""
          hash = Digest::MD5.hexdigest(b)
          return hash
        end

        #      def get_parm_value(parm_name)
        #        parm_value = ""
        #        self.get_parms.each do |parm|
        #          if parm =~ /^#{Regexp.quote(parm_name)}=/i then
        #            dummy = parm.split(/=/)
        #            if dummy.length > 1 then
        #              #  parm_value=dummy[1].gsub(/^[ ]*/,"")
        #              parm_value=dummy[1].strip
        #            end
        #          end
        #        end
        #        return parm_value
        #      end

        def post_parm_value(parm_name)
          parm_value = ""
          self.post_parms.each do |parm|
            if parm =~ /#{Regexp.quote(parm_name)}/i then
              dummy = parm.split(/=/)
              if dummy.length > 1 then
                parm_value = dummy[1].strip
              else
                # puts "Uhhhh ... need parameter value from '#{parm}''"
              end
            end
          end
          return parm_value
        end

        def has_body?
          self.raw_body.nil? ? false : true
        end

        def __connection_close?
          headers("Connection") do |h|
            return true if h =~ /close/i
          end
          return false
        end

        def connection_close?
          headers("Connection") do |h|
            return false if h =~ /keep\-alive/i
          end
          return true
        end

        def has_header?(name)
          self.each do |l|
            return false if l.strip.empty?
            return true if l =~ /^#{name}:/i
          end
          return false
        end

        def raw_body
          begin
            return nil if self.nil? or self.length < 3
            # return "#{self.last.force_encoding('BINARY')}" if self[-2].strip.empty?
            return "#{self.last}" if self[-2].strip.empty?
          rescue
            return nil
          end
          nil
        end

        def body
          return nil unless raw_body
          required_charset = charset
          charset = (required_charset && ['ASCII', 'UTF-8'].include?(required_charset.upcase)) ? required_charset.upcase : 'UTF-8'
          s = raw_body
          s.encode!(charset, :invalid => :replace, :undef => :replace, :replace => '')
          s
        end

        def is_text?
          ct = self.content_type(nil)
          if ct.nil?
            return true if self.body_encoded.ascii_only?
            return false
          else
            return true if ct =~ /text/i
            return false
          end
        end

        def is_wwwform?
          ct = self.content_type
          return true if ct =~ /form/i
          return false
        end

        def is_json?
          ct = self.content_type
          return true if ct =~ /json/i
          return false
        end

        def is_xml?
          ct = self.content_type
          return true if ct =~ /xml/i
          return false
        end

        def is_multipart?
          ct = self.content_type
          return true if ct =~ /^multipart/i
          return false
        end

        def body_encoded_OLD_UNUSED
          b = self.body
          return nil if b.nil?

          cs = self.charset
          return b.unpack("C*").pack("C*") if cs.nil?

          begin
            # not sure if this is a good idea???
            # return  b.encode(cs, :invalid => :replace, :undef => :replace, :replace => '').unpack("C*").pack("C*")
          rescue => bang
            if $DEBUG
              puts bang
              puts bang.backtrace
            end
          end
          return b.unpack("C*").pack("C*")
        end

        alias :body_encoded :body

        def status_code
          if self.first =~ /^HTTP\/... (\d+) /
            return $1
          else
            return nil
          end
        end

        alias :responseCode :status_code

        # returns array of new cookies
        # Iterating over Response and looks for Set-Cookie Headers
        # Set-Cookie: mycookie=b41dc9e55d6163f78321996b10c940edcec1b4e55a76464c4e9d25e160ac0ec5b769806b; Path=/
        def new_cookies(&b)
          nc = []
          headers("Set-Cookie") do |h|
            begin
              cookie = Watobo::Cookie.new(h)
              yield cookie if block_given?
              nc << cookie
            rescue => bang
              puts bang if $VERBOSE
              puts bang.backtrace if $DEBUG
            end
          end
          nc
        end

        def status
          begin
            # Filter bad utf-8 chars
            dummy = self.first.nil? ? '' : self.first.unpack("C*").pack("C*")

            if dummy =~ /^HTTP\/1\.\d{1,2} (.*)/i then
              return $1.chomp
            else
              return ''
            end
          rescue => bang
            if $DEBUG
              puts "! No Status Available !".upcase
              puts bang
              puts bang.backtrace
            end
            return nil
          end
        end

        def charset
          cs = nil
          self.each do |line|
            break if line.strip.empty?
            if line =~ /^Content-Type: .*charset=([^;]*)/i then
              cs = $1.strip
              break
            end
          end
          return cs
        end

        # @return [Array] list of all header names
        # @param [&block] can be given
        def header_names(filter = nil, &b)
          hnames = []
          headers do |h|
            hsi = h.index(':')
            next if hsi.nil?
            hname = h[0..hsi - 1]
            yield hname if block_given?
            hnames << hname
          end
          hnames
        end

        def headers(filter = nil, &b)
          begin
            filter = '.*' if filter.nil?
            header_list = []
            self.each_with_index do |hl, i|
              next if i == 0 # skip first entry -> Request Line
              line = "#{hl}"
              cl = line.force_encoding('ASCII-8BIT')
              return header_list if cl.strip.empty?
              if cl =~ /#{filter}/i
                yield line.strip if block_given?
                header_list.push line.strip
              end
            end
            return header_list
          rescue => bang
            puts bang
            puts bang.backtrace
            if $DEBUG
              puts bang.backtrace
              puts self.to_yaml
              binding.pry if binding.respond_to? :pry
            end
            return nil
          end
        end

      end

    end
  end
end