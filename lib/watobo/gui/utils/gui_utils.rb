# @private 
module Watobo#:nodoc: all
  module Gui
    module Utils
      
      def removeTags(text)
        if text.class.to_s =~ /Array/i then
          dummy = []
          text.each do |line|
            chunk = line.gsub(/<[^>]*>/,'').strip
            dummy.push chunk.gsub("\x00","") if chunk.length > 0
          end
          return dummy.join("\n")
        elsif text.class.to_s =~ /String/i then
          chunk = text.gsub(/<[^<]*>/,'').strip
          return chunk.gsub("\x00","")
          #return text.gsub(/\r/,"")
        end
      end

      def cleanupHTTP(text)

        if text.is_a?(Request) or text.is_a?(Response)
          dummy = []
          text.each do |line|
             clean = line.unpack("C*").pack("C*")
             clean.gsub!(/\r/,'')
             clean.strip!
             clean.gsub!("\x00","")
            dummy << clean
          end
          return dummy.join("\n")
        elsif text.is_a? String
          chunk = text.gsub(/\r/,'').strip
          return chunk.gsub("\x00","")
          #return text.gsub(/\r/,"")

        end
        return nil
      end

      def replace_text(text_box, string)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        text_box.removeText(pos,len)
        text_box.insertText(pos, string)
        text_box.setSelection(pos, string.length, true)
      end

      def addStringInfo(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string = text_box.extractText(pos, len)
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Info -")
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,( "Length: #{string.length} (0x%0.2x)" % string.length))

      end

      def addDecoder(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string2decode = text_box.extractText(pos, len)
        string2decode.extend Watobo::Mixin::Transcoders
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Decoder -")
        FXMenuSeparator.new(menu_pane)
        decodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{string2decode.b64decode}")
        decodeB64.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.b64decode)
        }
        decodeHex = FXMenuCommand.new(menu_pane,"Hex(A): #{string2decode.hexdecode}")
        decodeHex.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.hexdecode)
        }
        hex2int = FXMenuCommand.new(menu_pane,"Hex(Int): #{string2decode.hex2int}")
        hex2int.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.hex2int)
        }
        decodeURL = FXMenuCommand.new(menu_pane,"URL: #{string2decode.url_decode}")
        decodeURL.connect(SEL_COMMAND) {
          replace_text(text_box, string2decode.url_decode)
        }

      end

      def addEncoder(menu_pane, text_box)
        pos = text_box.selStartPos
        len = text_box.selEndPos - pos
        string2encode = text_box.extractText(pos, len)
        string2encode.extend Watobo::Mixin::Transcoders
        FXMenuSeparator.new(menu_pane)
        FXMenuCaption.new(menu_pane,"- Encoder -")
        FXMenuSeparator.new(menu_pane)
        encodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{string2encode.b64encode}")
        encodeB64.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.b64encode)
        }
        encodeHex = FXMenuCommand.new(menu_pane,"Hex: #{string2encode.hexencode}")
        encodeHex.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.hexencode)
        }
        encodeURL = FXMenuCommand.new(menu_pane,"URL: #{string2encode.url_encode}")
        encodeURL.connect(SEL_COMMAND) {
          replace_text(text_box, string2encode.url_encode)
        }

      end
    end
  end
end
