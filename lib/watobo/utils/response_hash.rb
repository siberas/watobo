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

        # remove path elements from response
        body.gsub!(/#{Regexp.quote(request.path_ext)}/, '')
        body.gsub!(/#{Regexp.quote(request.path)}/, '')
        request.subdirs.reverse.each do |d|
          body.gsub!(/#{Regexp.quote(d)}/, '')
        end

        # remove request parameters (values) from response
        request.parameters.each do |parm|
          body.gsub!(/#{Regexp.quote(parm.name)}/, '')
          body.gsub!(/#{Regexp.quote(parm.value.to_s)}/, '')
        end
        # remove date format 01.02.2009
        body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
        # remove date format 02/2009
        body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
        # remove time
        body.gsub!(/\d{1,2}:\d{1,2}(:\d{1,2})?/, '')

        crc = "%.8X" % Zlib.crc32(body)
        return crc

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return ''

    end

    # returns md5 [String] of cleaned response body
    def self.responseHash(request, response)
      return Digest::MD5.hexdigest(clean_response(request, response))
    end

    def self.clean_response(request, response)
      begin
        return nil if request.nil? || response.nil?
        cleaned_response = response.headers.select { |h| !h.match?(/^Dat/) && !h.match?(/^Content/) }.join("\r\n")
        cleaned_response << "\r\n"
        if response.has_body?
          required_charset = response.charset
          charset = ( required_charset && ['ASCII','UTF-8'].include?(required_charset.upcase)) ? required_charset.upcase : 'UTF-8'
          body = response.body.to_s.dup
          body.encode!(charset, :invalid => :replace, :undef => :replace, :replace => '')

          body_text = Nokogiri::HTML(body).text rescue body
          cleaned_response << body_text

          # remove all parm/value pairs
          request.get_parm_names.each do |p|
            cleaned_response.gsub!(/\b#{ascii_regex(p)}\b/, '') if p.length > min_len
            val = request.get_parm_value(p)
            cleaned_response.gsub!(/\b#{ascii_regex(val)}\b/, '') if val.length > min_len
          end

          request.post_parm_names.each do |p|
            cleaned_response.gsub!(/\b#{Regexp.quote(p)}\b/, '') if p.length > min_len
            val = request.post_parm_value(p)
            cleaned_response.gsub!(/\b#{Regexp.quote(val)}\b/, '') if val.length > min_len
          end
          # remove date format 01.02.2009
          cleaned_response.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
          # remove date format 02/2009
          cleaned_response.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
          # Remove dates in mm/dd/yyyy format
          cleaned_response.gsub!(/\d{1,2}\/\d{1,2}\/\d{4}/, '')

          # Remove dates in yyyy-mm-dd format
          cleaned_response.gsub!(/\d{4}-\d{1,2}-\d{1,2}/, '')

          # Remove times in hh:mm:ss format
          cleaned_response.gsub!(/\d{1,2}:\d{2}:\d{2}/, '')

          # Remove times in hh:mm format
          cleaned_response.gsub!(/\d{1,2}:\d{2}/, '')

          # finally we clean empty lines and unwanted spaces
          cleaned_response.gsub!(/\s+/, ' ')
          # Remove empty lines
          cleaned_response.gsub!(/^\s*$\n/, '')
        end

        return cleaned_response

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
          # body.gsub!(/\P{ASCII}/, '')
          charset = response.charset
          unless charset.nil?
            begin
              body.encode!(charset, :invalid => :replace, :undef => :replace, :replace => '')
            rescue
              body = response.body.dup
            end
          end
          # body.encode!('ASCII', :invalid => :replace, :undef => :replace, :replace => '')
          # body.encode!('ISO-8859-1', :invalid => :replace, :undef => :replace, :replace => '')
          # remove possible chunk values
          body.gsub!(/\r\n[0-9a-fA-F]+\r\n/, '')
          # remove date format 01.02.2009
          body.gsub!(/\d{1,2}\.\d{1,2}.\d{2,4}/, "")
          # remove date format 02/2009
          body.gsub!(/\d{1,2}(.\|\/)d{2,4}/, "")
          # remove time
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
          # puts md5
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