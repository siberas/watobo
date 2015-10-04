module Watobo
  module UTF16
     def self.decode_utf16le(str)
        str.force_encoding(Encoding::UTF_16LE)
        str.encode(Encoding::UTF_8, Encoding::UTF_16LE).force_encoding('UTF-8')
      end

      def self.encode_utf16le(str)
        str = str.force_encoding('UTF-8') if [::Encoding::ASCII_8BIT,::Encoding::US_ASCII].include?(str.encoding)
        str.dup.force_encoding('UTF-8').encode(Encoding::UTF_16LE, Encoding::UTF_8).force_encoding('UTF-8')
      end
  end
end