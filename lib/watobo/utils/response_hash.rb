require 'digest/md5'

# @private 
module Watobo #:nodoc: all
  module Utils

    def self.ascii_regex(s)
      s.encode!('ASCII', :invalid => :replace, :undef => :replace)
      Regexp.quote s.unpack("C*").pack("C*")
    end

    # based on the following article a faster algorithm is choosen
    # http://blog.thecodingfrog.com/2009/06/performance-benchmark-of-crc32-md5-and.html
    #
    def self.response_checksum(request, response)
      begin

        body = response.to_s

        request.parameters.each do |parm|
          body.gsub!(/#{Regexp.quote(parm.name)}/, '')
          body.gsub!(/#{Regexp.quote(parm.value.to_s)}/, '')
        end
        # remove date format 01.02.2009
        body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
        # remove date format 02/2009
        body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
        #remove time
        body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')

        crc = "%.8X" % Zlib.crc32(body)
        return crc

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return ''

    end

    # returns [Array]
    # array[0] contains the cleaned content (body)
    # array[1] contains the MD5 hash (hexdigest)
    def self.responseHash(request, response)
      begin
        if request.body and response.body then
          body = response.body.dup

          # remove all parm/value pairs
          request.get_parm_names.each do |p|
            body.gsub!(/#{ascii_regex(p)}/, '')
            body.gsub!(/#{ascii_regex(request.get_parm_value(p))}/, '')
          end
          request.post_parm_names.each do |p|
            body.gsub!(/#{Regexp.quote(p)}/, '')
            val = request.post_parm_value(p)
            body.gsub!(/#{Regexp.quote(val)}/, '')
          end
          # remove date format 01.02.2009
          body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
          # remove date format 02/2009
          body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
          #remove time
          body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')

          return body, Digest::MD5.hexdigest(body)

        elsif response.body then
          return body, Digest::MD5.hexdigest(response.body)
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return nil

    end

    def Utils.remove_string(data, remove)
      plain = "#{remove}"
      data.gsub!(/#{Regexp.quote(remove)}/, '')
      cgi_esc = CGI::unescape(p)
      data.gsub!(/#{Regexp.quote(cgi_esc)}/, '')
    end

    # smart hashes are necessary for blind sql injections tests
    # SmartHash means that all dynamic information is removed from the response before creating the hash value.
    # Dynamic information could be date&time as well as parameter names and theire valuse.
    def Utils.smartHash(orig_request, request, response)
      min_length = 4
      begin
        if request and response.body then
          # puts response.content_type

          # puts charset
          body = response.body.dup
          #body.gsub!(/\P{ASCII}/, '')
          charset = response.charset
          unless charset.nil?
            begin
              body.encode!(charset, :invalid => :replace, :undef => :replace, :replace => '')
            rescue
              body = response.body.dup
            end
          end
          #body.encode!('ASCII', :invalid => :replace, :undef => :replace, :replace => '')
          #body.encode!('ISO-8859-1', :invalid => :replace, :undef => :replace, :replace => '')
          # remove possible chunk values
          body.gsub!(/\r\n[0-9a-fA-F]+\r\n/, '')
          # remove date format 01.02.2009
          body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
          # remove date format 02/2009
          body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
          #remove time
          body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')
          # remove all non-printables
          body.gsub!(/[^[:print:]]/, '')

          replace_items = []

          request.get_parm_names.each do |p|
            replace_items << p if p.length >= min_length
            val = request.get_parm_value(p)
            replace_items << val if val.length >= min_length
          end

          request.post_parm_names.each do |p|
            replace_items << p if p.length >= min_length
            val = request.post_parm_value(p)
            replace_items << val if val.length >= min_length

          end

          orig_request.get_parm_names.each do |p|
            replace_items << p if (p.length >= min_length)
            val = orig_request.get_parm_value(p)
            replace_items << val if (val.length >= min_length)
          end

          orig_request.post_parm_names.each do |p|
            replace_items << p if p.length >= min_length
            val = orig_request.post_parm_value(p)
            replace_items << val if val.length >= min_length
          end

          replace_items.uniq.sort.each do |p|
            body.gsub!(/#{ascii_regex(p)}/, '')
            body.gsub!(/#{ascii_regex(CGI::unescape(p))}/, '')
          end
          md5 = Digest::MD5.hexdigest(body)
          #puts md5
          return body, md5
        else
          # no response body. create hash from header
          unless response.respond_to? :removeHeader
            Watobo::Response.create response
          end
          response.removeHeader("Date")
          response.removeHeader("Set-Cookie")
          return response, Digest::MD5.hexdigest(response.join)
        end
      rescue => bang
        # puts "VAL_CGI_Q: #{val_cgi_q}"
        # return some random hash in case of an error
        puts bang if $DEBUG
        puts bang.backtrace if $DEBUG

        return body, Digest::MD5.hexdigest(Time.now.to_f.to_s + rand(10000).to_s)
      end
    end
  end
end