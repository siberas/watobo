module Watobo
  module Gui
    class SidPreview < FXText
      def highlight(pattern)
        # text_encoded = self.to_s.force_encoding('iso-8859-1').encode('utf-8', :invalid=>:replace)
        text_encoded = self.to_s.force_encoding('ASCII-8BIT').scrub
        text_encoded = self.to_s.encode('UTF-8', :invalid=>:replace, :replace => '')
        self.setText(text_encoded)
        text_encoded = self.to_s
        begin
          #  puts pattern
          #  if self.to_s =~ /#{pattern}/ then
          if text_encoded =~ /#{pattern}/ then
            # binding.pry
            match = $&
            if $1 and $2 then
              puts "MATCH: #{match}"
              puts "#1: #{$1}"
              puts "#2: #{$2}"
              puts
              string1 = $1
              string2 = $2
              index1 = nil
              #index1 = self.to_s.index(string1)
              index1 = text_encoded.index(match)
              if index1 then
                self.changeStyle(index1,string1.length,1)
                puts text_encoded[index1..index1+20]
              end

              index2 = text_encoded.index(string2, index1)

              if index2 then
                self.changeStyle(index2,string2.length,1)
                puts text_encoded[index2..index2+20]
              end

              self.makePositionVisible(index2)

            else
              #     string1 = pattern
              #     string2 = pattern
            end
          end
        rescue => bang
          puts "!!!ERROR: could not highlight pattern"
          puts bang
        end
      end

      def initialize(parent, opts)
        super(parent, opts)
        @style = 1 # default style

        # Construct some hilite styles
        hs_green = FXHiliteStyle.new
        hs_green.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_green.normalBackColor = FXRGBA(0,255,0,1)   # FXColor::White
        hs_green.style = FXText::STYLE_BOLD

        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
        hs_red.style = FXText::STYLE_BOLD

        self.styled = true
        # Set the styles
        self.hiliteStyles = [ hs_green, hs_red]

        self.editable = false
      end
    end

    def onPatternClick(sender,sel,item)
      @request_viewer.highlight(@pattern_list.getItemText(item))
      @response_viewer.highlight(@pattern_list.getItemText(item))
      @pattern.value = @pattern_list.getItemText(item)
      @pattern_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
    end

    def onRequestChanged(sender, sel, item)
      begin
        chat = @requestCombo.getItemData(@requestCombo.currentItem)
        @request_viewer.setText(cleanupHTTP(chat.request))
        @response_viewer.setText(cleanupHTTP(chat.response))
      rescue => bang
        puts "could not update request"
        puts bang
      end
    end

    def showBadPatternMessage()
      FXMessageBox.information(self, MBOX_OK, "Wrong Pattern Format", "SID Pattern Format is wrong, e.g.(<PATTERN>) <(session)=([a-z]*)>\nRegex must contain two selectors \"()\" to satisfy $1 and $2.")
    end

    def getSidPatternList()
      sids = []
      @pattern_list.numItems.times do |index|
        sids.push @pattern_list.getItemData(index)
      end
      return sids
    end

    def addPattern(sender,sel,id)
      pattern = @pattern.value
      if pattern != "" then
        begin
          dummy = pattern.split('(')
          if dummy.length < 2 then
            # no good pattern
            puts "!!!ERROR: Bad pattern"
            showBadPatternMessage()
            return -1
          end

          dummy = pattern.split(')')
          if dummy.length < 2 then
            # no good pattern
            puts "!!!ERROR: Bad pattern"
            showBadPatternMessage()
            return -1
          end

          # test if pattern looks like a valid regex
          if "test" =~ /#{pattern}/i then
            #looks good
          end

        rescue => bang
          puts "!!!ERROR: Bad pattern"
          showBadPatternMessage()
          return -1
        end
        item = @pattern_list.appendItem("#{@pattern.value}")
        @pattern_list.setItemData(item, @pattern.value)
        return 0
        # item.
      end
    end
  end
end