# @private 
module Watobo#:nodoc: all
  module Gui
    class TokenSettings < FXHorizontalFrame
      include Watobo::Gui::Utils
      
      class SidPreview_UNUSED < FXText
        def highlight(pattern)
          self.setText(self.to_s)
          begin
            #  puts pattern
            if self.to_s =~ /#{pattern}/ then
              if $1 and $2 then
                #   puts "MATCH (#{$1}/#{$2})"
                string1 = $1
                string2 = $2
                index1 = nil
                index1 = self.to_s.index(string1)
                if index1 then
                  self.changeStyle(index1,string1.length,1)
                end
                index2 = nil
                index2 = self.to_s.index(string2)

                if index2 then
                  self.changeStyle(index2,string2.length,1)
                end

                self.makePositionVisible(index2+string2.length)
                self.makePositionVisible(index1)

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

      def getTokenPatterns()
        sids = []
        @pattern_list.numItems.times do |index|
          sids.push @pattern_list.getItemData(index)
        end
        return sids
      end

      def updateRequests(req_id_list)        
          @requestCombo.clearItems()

          req_id_list.each do |id|
            chat = Watobo::Chats.get_by_id(id)
            text = "[#{id}] #{chat.request.first}"
            @requestCombo.appendItem(text.slice(0..60), chat)
          end

          unless @target_chat.nil?
            text = "[TARGET #{@target_chat.id}] - #{@target_chat.request.first}"
            @requestCombo.appendItem(text.slice(0..60), @target_chat)
          end

          if @requestCombo.numItems > 0 then
            if @requestCombo.numItems < 10 then
              @requestCombo.numVisible = @requestCombo.numItems
            else
              @requestCombo.numVisible = 10
            end

            @requestCombo.setCurrentItem(0, true)
            chat = @requestCombo.getItemData(0)
            @request_viewer.setText(cleanupHTTP(chat.request))
            @response_viewer.setText(cleanupHTTP(chat.response))
          end
        
      end

      private

      def onPatternClick(sender,sel,item)
        pattern = @pattern_list.getItemText(item)
        @request_viewer.highlight(pattern)
        @response_viewer.highlight(pattern)
        @pattern.value = pattern
        @pattern_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def onRequestChanged(sender, sel, item)
        begin
          chat = @requestCombo.getItemData(@requestCombo.currentItem)
          puts "selected #{chat.class}"
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

      def remPattern(sender,sel,id)
        index = @pattern_list.currentItem
        if  index >= 0
          @pattern_list.removeItem(index)
        end
      end

      def initialize(parent, target_chat=nil)
      
        @pattern = FXDataTarget.new('')
        @target_chat = target_chat

        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        main_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_GROOVE)
        frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_Y)
        label = FXLabel.new(frame, "CSRF Token Patterns:")

        @pattern_field = FXTextField.new(frame, 40, :target => @pattern, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)

        b_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @addSidButton = FXButton.new(b_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @addSidButton.connect(SEL_COMMAND, method(:addPattern))
        @remSidButton=FXButton.new(b_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @remSidButton.connect(SEL_COMMAND, method(:remPattern))

        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @pattern_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @pattern_list.numVisible = 25

        @pattern_list.connect(SEL_COMMAND,method(:onPatternClick))

        frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X)
        label = FXLabel.new(frame, "Token Script Requests:")
        @requestCombo = FXComboBox.new(frame, 5, nil, 0,
        COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        #@filterCombo.width =200

        @requestCombo.numVisible = 0
        @requestCombo.numColumns = 50
        @requestCombo.editable = false
        @requestCombo.connect(SEL_COMMAND, method(:onRequestChanged))

        chat_viewer_frame = FXVerticalFrame.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y, :height => 300, :padding => 0)
        tabBook = FXTabBook.new(chat_viewer_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT, :padding => 0)

        req_tab = FXTabItem.new(tabBook, "Request", nil)
        frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
        @request_viewer = SidPreview.new(sunken, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)

        resp_tab = FXTabItem.new(tabBook, "Response", nil)
        frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
        @response_viewer = SidPreview.new(sunken, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        Watobo::Conf::OttCache.patterns.each do |p|
            item = @pattern_list.appendItem("#{p}")
            @pattern_list.setItemData(item, p)
          end
          
        unless @target_chat.nil?
        @request_viewer.text = cleanupHTTP(@target_chat.request)
        @response_viewer.text = cleanupHTTP(@target_chat.response)
        end
      end
    end

    class TokenScriptSettings < FXVerticalFrame
      
      include Watobo::Constants
      
      def showChat(chat)
        @request_viewer.setText(chat.request)

        @response_viewer.setText(chat.response)

      end

      def getTokenScriptIds()
        ids = []
        @scriptTable.numRows.times do |row|
          # puts row
          ids.push @scriptTable.getRowText(row)
        end
        return ids

      end

      def onTableClick(sender, sel, item)
        begin

          # purge viewers
          @request_viewer.setText('')
          @response_viewer.setText('')
          row = item.row

          if row >= 0 then
            @scriptTable.selectRow(row, false)
            chatid = @scriptTable.getRowText(item.row).to_i
            # @logText.appendText("selected ID: (#{chatid})\n")
            if chatid >= 0
              chat = Watobo::Chats.get_by_id(chatid)
              showChat(chat) if chat
              @sel_row = row
              @rem_button.enable
            end
          end
        rescue => bang
          puts "!!!ERROR: onTableClick"
          puts bang
          puts "!!!"

        end
      end

      def removeRequest(sender, sel, item)
        if @sel_row >= 0 then
          @scriptTable.removeRows(@sel_row)
          @scriptTable.killSelection(false)
          @rem_button.disable
          @sel_row = -1
        end
      end

      def startSelectChatDialog(sender, sel, item)
        begin
          dlg = Watobo::Gui::SelectChatDialog.new(self, "Select Login Chat")
          if dlg.execute != 0 then

            chats_selected = dlg.selection.value.split(",")

            chats_selected.each do |chatid|
              chat = Watobo::Chats.get_by_id(chatid.strip)
              addRequest(chat) if chat
            end
          end
        rescue => bang
          puts "!!!ERROR: could not open SelectChatDialog."
          puts bang
        end
      end

      def addRequest(chat)
        @scriptTable.addChat(chat)
      end

      def initialize(parent, target_chat)
        @target_chat = target_chat
        @table_filter = FXDataTarget.new('')
        @sel_row = -1
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        splitter = FXSplitter.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SPLITTER_VERTICAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
        script_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :height => 300,:padding => 0)

        frame = FXHorizontalFrame.new(script_frame, :opts => LAYOUT_FILL_X)
        label = FXLabel.new(frame, "Token Script Requests:")
        @add_button = FXButton.new(frame, "Add Request...", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
        @add_button.connect(SEL_COMMAND, method(:startSelectChatDialog))

        @rem_button = FXButton.new(frame, "Remove Request", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
        @rem_button.connect(SEL_COMMAND, method(:removeRequest))
        @rem_button.disable

        label.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        script_table_frame = FXVerticalFrame.new(script_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @scriptTable = ConversationTable.new(script_table_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @scriptTable.connect(SEL_CLICKED, method(:onTableClick))

        chat_viewer_frame = FXVerticalFrame.new(splitter, LAYOUT_FILL_X|LAYOUT_FILL_Y, :height => 300, :padding => 0)
        tabBook = FXTabBook.new(chat_viewer_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT, :padding => 0)

        req_tab = FXTabItem.new(tabBook, "Request", nil)
        frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @request_viewer = Watobo::Gui::SimpleTextView.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)

        resp_tab = FXTabItem.new(tabBook, "Response", nil)
        frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @response_viewer = Watobo::Gui::SimpleTextView.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)

        
          Watobo::OTTCache.chats(@target_chat) do |chat|
            addRequest(chat)
          end
      end
    end

    #
    # S E S S I O N   M A N A G E M E N T   D I A L O G
    #
    class CSRFTokenDialog < FXDialogBox
      
      include Watobo::Constants
      include Watobo::Gui::Icons
      
      def getTokenPatterns()
        token_patterns = @tokenSettings.getTokenPatterns()
      end

      def getTokenScriptIds()
        get_token_chat_ids = @tokenScriptSettings.getTokenScriptIds()
      end

      def initialize(owner, target_chat=nil)
        @target_chat = target_chat
        # Invoke base class initialize function first
        #  super(owner, "LoginScript Wizzard", DECOR_TITLE|DECOR_BORDER,:width=>800, :height=>600)
        super(owner, "One-Time-Token Management", DECOR_ALL, :width=>800, :height=>600)
        self.icon = ICON_TOKEN
        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        tabBook = FXTabBook.new(main_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

        login_tab = FXTabItem.new(tabBook, "Token Script", nil)
        @tokenScriptSettings = TokenScriptSettings.new(tabBook, @target_chat)

        sid_tab = FXTabItem.new(tabBook, "Token Patterns", nil)
        # @sidFrame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @tokenSettings = TokenSettings.new(tabBook, @target_chat)

        #  logout_tab = FXTabItem.new(tabBook, "Logout Signatures", nil)
        #  @logoutSettings = LogoutSettings.new(tabBook, @project)

        tabBook.connect(SEL_COMMAND) do |sender, sel, tabItem|
          case tabItem.to_i
          when 0
            #  puts "Login Script Selected"
          when 1
            # puts "Session IDs Selected"
            ids = getTokenScriptIds()
            @tokenSettings.updateRequests(ids)
          when 2
            #   puts "Logout Selected"
          end
        end

        button_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
        FXButton.new(button_frame, "OK" ,
        :target => self, :selector => FXDialogBox::ID_ACCEPT,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        FXButton.new(button_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
      end

    end
    #--
  end
end
