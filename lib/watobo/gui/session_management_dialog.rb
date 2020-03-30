# @private 
module Watobo#:nodoc: all
  module Gui
    class SidTable < FXTable
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def updateSID_UNUSED(new_sids = {})
        initTable()
        new_sids.each_key do |site|
          addSID(site, new_sids[site])
        end
      end

      def initialize(owner, opts)
        super(owner, opts)
        @request = nil
        @event_dispatcher_listeners = Hash.new
        initTable()

        self.connect(SEL_COMMAND, method(:onTableClick))

        self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
          self.fitColumnsToContents(index)
        end
        
        Watobo::SIDCache.acquire(Thread.current.object_id).sids.each_key do |site|
           addSID(site, new_sids[site])
        end
      end

      private

      def onTableClick(sender, sel, item)
        begin
          row = item.row
          self.selectRow(row, false)
          #      self.startInput(row,2)
        rescue => bang
          puts bang
        end
      end
=begin
      def addKeyHandler(item)
        item.connect(SEL_KEYPRESS) do |sender, sel, event|
          cr = self.currentRow
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )

          if @ctrl_pressed
            # special handling of KEY_Return, because we don't want a linebreak in textbox.
            if event.code == KEY_Return
              self.acceptInput(true)
              notify(:hotkey_ctrl_enter)
              true
            else
              notify(:hotkey_ctrl_f) if event.code == KEY_f
              notify(:hotkey_ctrl_s) if event.code == KEY_s

              if event.code == KEY_u
                text = self.getItemText(cr, 2)
                #puts "* Encode URL: #{text}"
                cgi = CGI::escape(text)
                self.acceptInput(true)
                self.setItemText(cr, 2, cgi.strip, true)
              end

              if event.code == KEY_b
                text = self.getItemText(cr, 2)
                puts "* Encode B64: #{text}"
                b64 = Base64.encode64(text)
                self.acceptInput(true)
                self.setItemText(cr, 2, b64.strip, true)
                puts b64.class
              end

              puts "CTRL-SHIFT-U" if event.code == KEY_U
              if event.code == KEY_U

                text = self.getItemText(cr, 2)
                puts "* Encode URL: #{text}"
                uncgi = CGI::unescape(text)
                self.acceptInput(true)
                self.setItemText(cr, 2, uncgi.strip, true)
              end
              if event.code == KEY_B
                text = self.getItemText(cr, 2)
                puts "* Encode B64: #{text}"
                b64 = Base64.decode64(text)
                self.acceptInput(true)
                self.setItemText(cr, 2, b64.strip, true)
                puts b64.class
              end

              false
            end
          elsif event.code == KEY_Return
            self.selectRow(cr)
            startInput(cr,2)
            true
          else
            #puts "%04x" % event.code
            false
          end
        end

        item.connect(SEL_KEYRELEASE) do |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        end
      end
=end

      def addSID(host, sids)
        sids.each_key do |sid_name|
          lastRowIndex = self.getNumRows
          self.appendRows(1)
          self.setItemText(lastRowIndex, 0, host)
          self.getItem(lastRowIndex, 0).justify = FXTableItem::LEFT
          self.setItemText(lastRowIndex, 1, sid_name)
          self.getItem(lastRowIndex, 1).justify = FXTableItem::LEFT
          self.setItemText(lastRowIndex, 2, sids[sid_name])
          self.getItem(lastRowIndex, 2).justify = FXTableItem::LEFT
        end
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def initTable
        self.clearItems()
        self.setTableSize(0, 3)

        self.setColumnText( 0, "Host" )
        self.setColumnText( 1, "Name" )
        self.setColumnText( 2, "Value" )

        self.rowHeader.width = 0
        self.setColumnWidth(0, 60)

        self.setColumnWidth(1, 80)
        self.setColumnWidth(2, 120)

      end
    end

    class LogoutSettings < FXHorizontalFrame
      def showBadSignatureMessage()
        FXMessageBox.information(self, MBOX_OK, "Wrong Signature Format", "Signature Format is wrong. Must be a valid regular expression, e.g.(<Regex>) <^Location.*action=logout>")
      end

      def getLogoutSignatures()
        signatures = []
        @signature_list.numItems.times do |index|
          signatures.push @signature_list.getItemData(index)
        end
        return signatures
      end

      def addSignature(sender,sel,id)
        pattern = @signature.value
        if pattern != "" then
          begin

            # test if pattern looks like a valid regex
            if "test" =~ /#{pattern}/i then
              #looks good
            end

          rescue => bang
            puts "!!!ERROR: Bad pattern"
            showBadSignatureMessage()
            return -1
          end
          item = @signature_list.appendItem("#{@signature.value}")
          @signature_list.setItemData(item, @signature.value)
          return 0
          # item.
        end
      end

      def remSignature(sender,sel,id)
        index = @signature_list.currentItem
        if  index >= 0
          @signature_list.removeItem(index)
        end
      end

      def onSignatureClick(sender,sel,item)
        #@request_viewer.highlight(@pattern_list.getItemText(item))
        #@response_viewer.highlight(@pattern_list.getItemText(item))
        @signature.value = @signature_list.getItemText(item)
        @signature_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def initialize(parent)
        @project = Watobo.project
        @signature = FXDataTarget.new('')

        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        main_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_GROOVE)
        frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_Y)
        label = FXLabel.new(frame, "Logout Signatures:")

        @signature_field = FXTextField.new(frame, 40, :target => @signature, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)

        b_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @addSigButton = FXButton.new(b_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @addSigButton.connect(SEL_COMMAND, method(:addSignature))
        @remSigButton=FXButton.new(b_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
        @remSigButton.connect(SEL_COMMAND, method(:remSignature))

        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @signature_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @signature_list.numVisible = 25

        @signature_list.connect(SEL_COMMAND,method(:onSignatureClick))

        
        Watobo::Conf::Scanner.logout_signatures.each do |p|
            item = @signature_list.appendItem("#{p}")
            @signature_list.setItemData(item, p)
          end
        
      end
    end

    class SessionIdSettings < FXHorizontalFrame
      include Watobo::Gui::Utils

      class SidPreview_UNUSED < FXText
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

      def remPattern(sender,sel,id)
        index = @pattern_list.currentItem
        if  index >= 0
          @pattern_list.removeItem(index)
        end
      end

      def updateRequests(req_id_list)

        if @project then
          @requestCombo.clearItems()

          req_id_list.each do |id|
            chat = Watobo::Chats.get_by_id(id)
            text = "[#{id}] #{chat.request.first}"
            @requestCombo.appendItem(text.slice(0..60), chat)
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
      end

      def initialize(parent)
        @project = Watobo.project
        @pattern = FXDataTarget.new('')

        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        main_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_GROOVE)
        frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_Y)
        label = FXLabel.new(frame, "Session ID Patterns:")

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
        label = FXLabel.new(frame, "Login Requests:")
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

        
        Watobo::Conf::SidCache.patterns.each do |p|
            item = @pattern_list.appendItem("#{p}")
            @pattern_list.setItemData(item, p)
          end
        
      end
    end

    class SIDCacheFrame < FXVerticalFrame
      def initialize(parent)
        @project = Watobo.project
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
      #  button_frame = FXHorizontalFrame.new(self, :opts=> LAYOUT_FILL_X)
      #  refresh_btn = FXButton.new(button_frame, "Refresh")

        @sidTable = SidTable.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
       # sid_cache = Watobo::SIDCache.acquire(Thread.current.object_id)
        
        #@sidTable.updateSID @session.sidCache()
      end
    end

    class LoginScriptSettings < FXVerticalFrame
      def showChat(chat)
        @request_viewer.setText(chat.request)

        @response_viewer.setText(chat.response)

      end

      def getLoginScriptIds()
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

      def  addRequest(chat)
        @scriptTable.addChat(chat)
      end

      def initialize(parent)
        @project = Watobo.project
        @table_filter = FXDataTarget.new('')
        @sel_row = -1
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        # main_splitter = FXSplitter.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
        # left_frame = FXVerticalFrame.new(main_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :width => 400, :padding => 0)
        #  right_frame = FXVerticalFrame.new(main_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 200, :padding => 0)

        #chat_filter_frame = FXHorizontalFrame.new(left_frame, :opts => LAYOUT_FILL_X)
        #FXLabel.new(chat_filter_frame, "Filter")
        #@filter_text_field = FXTextField.new(chat_filter_frame, 20, @table_filter, FXDataTarget::ID_VALUE, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)

        #chat_table_frame = FXVerticalFrame.new(left_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        splitter = FXSplitter.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SPLITTER_VERTICAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
        script_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :height => 300,:padding => 0)

        frame = FXHorizontalFrame.new(script_frame, :opts => LAYOUT_FILL_X)
        label = FXLabel.new(frame, "Login Script Requests:")
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

        if @project.respond_to? :getLoginChatIds then
          @project.getLoginChatIds.each do |id|
            chat = Watobo::Chats.get_by_id(id)
            addRequest(chat)
          end
        end
      end
    end

    #
    # S E S S I O N   M A N A G E M E N T   D I A L O G
    #
    class SessionManagementDialog < FXDialogBox
      include Watobo::Gui::Icons
      
      def getSidPatterns()
        sidpats = @sidSettings.getSidPatternList
      end

      def getLoginScriptIds()
        login_chat_ids = @loginSettings.getLoginScriptIds()
      end

      def getLogoutSignatures()
        signatures = @logoutSettings.getLogoutSignatures()
      end

      def initialize(owner)
        #@project = project
        # Invoke base class initialize function first
        #  super(owner, "LoginScript Wizzard", DECOR_TITLE|DECOR_BORDER,:width=>800, :height=>600)
        super(owner, "Session Management", DECOR_ALL, :width=>800, :height=>600)
        self.icon = ICON_LOGIN_WIZZARD
        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        tabBook = FXTabBook.new(main_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        @loginSettings = nil
        @sidSettings = nil
        
        unless Watobo.project.nil?

        login_tab = FXTabItem.new(tabBook, "Login Script", nil)
        @loginSettings = LoginScriptSettings.new(tabBook)

       
        end
         sid_tab = FXTabItem.new(tabBook, "Sesssion IDs", nil)
        # @sidFrame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @sidSettings = SessionIdSettings.new(tabBook)

        logout_tab = FXTabItem.new(tabBook, "Logout Signatures", nil)
        @logoutSettings = LogoutSettings.new(tabBook)

#        unless Watobo.project.nil?
#        sidcache_tab = FXTabItem.new(tabBook, "SID-Cache", nil)
#        SIDCacheFrame.new(tabBook)
#        end
        
        tabBook.connect(SEL_COMMAND) do |sender, sel, tabItem|

          case tabItem.to_i
          when 0
            #  puts "Login Script Selected"
          when 1
            # puts "Session IDs Selected"
            unless Watobo.project.nil?
            ids = getLoginScriptIds()
            @sidSettings.updateRequests(ids)
            end
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
