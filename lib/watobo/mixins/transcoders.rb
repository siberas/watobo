# @private 
module Watobo#:nodoc: all
  module Mixin
    module Transcoders
      def url_encode
        CGI::escape(self)
      end

      def url_decode
        CGI::unescape(self)
      end

      def b64decode
        err_count = 0          
        begin
          b64string = self.force_encoding('ASCII-8BIT')
          rs = Base64.strict_decode64(b64string)
          #rs = Base64.decode64(b64string)
          return rs
        rescue
          #b64string.gsub!(/.$/,'')
          #err_count += 1
          #retry if err_count < 4
          return self.to_s
        end
      end

      def b64encode
        begin
          plain = self.force_encoding('ASCII-8BIT')
          #rs = Base64.strict_encode64(plain)
          rs = Base64.strict_encode64(plain)
          # we only need a simple string without linebreaks
          #rs.gsub!(/\n/,'')
          #rs.strip!
          return rs
        rescue
          return self.to_s
        end
      end

      def hex2int
        begin
          plain = self.strip
          if plain =~ /^[0-9a-fA-F]{1,8}$/ then
          return plain.hex
          else
            return ""
          end
        rescue
          return ""
        end
      end

      def hexencode
        begin

          self.unpack("H*")[0]
        rescue
          return ""
        end

      end

      def hexdecode

        [ self ].pack("H*")
      end
    end
  end
end
