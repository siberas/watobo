# @private 
module Watobo#:nodoc: all
  module Gui
    class AddTableParmDialog < FXDialogBox
      attr :param
      
      def location()
        @location_combo.getItemData(@location_combo.currentItem)
      end

      def parmName()
        @parm_name_dt.value
      end

      def parmValue()
        @parm_value_dt.value
      end

      def initialize(owner)
        #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        super(owner, "Add Parameter", DECOR_ALL)

        @location = nil
        @pname = nil
        @pval = nil
        @param = nil

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        #  puts "create scopeframe with scope:"
        # @project.scope
        FXLabel.new(frame, "Location:")
        @location_combo = FXComboBox.new(frame, 5, nil, 0,
            COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        %w( WWWForm URL Cookie JSON ).each do |loc|
          item = @location_combo.appendItem(loc)
          @location_combo.setItemData(item, loc)
        end

        @location_combo.numVisible = 4
        @location_combo.numColumns = 8
        @location_combo.currentItem = 0
        @location_combo.editable = false
        #  @location_combo.connect(SEL_COMMAND, method(:onLocationChanged))

        FXLabel.new(frame, "Parameter:")
        @parm_name_dt = FXDataTarget.new('')
        FXTextField.new(frame, 15,
        :target => @parm_name_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        FXLabel.new(frame, "Value:")
        @parm_value_dt = FXDataTarget.new('')
        FXTextField.new(frame, 15,
        :target => @parm_value_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        buttons_frame = FXHorizontalFrame.new(base_frame,
        :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        @finishButton = FXButton.new(buttons_frame, "Add" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
        #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          create_param
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
            :target => self, :selector => FXDialogBox::ID_CANCEL,
            :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

      end
      
      private
      
      def create_param
        @param = case @location_combo.getItemData(@location_combo.currentItem)
        when /(Post|WWWForm)/i
         Watobo::WWWFormParameter.new(:name => @parm_name_dt.value, :value => @parm_value_dt.value)
         when /Url/i
           Watobo::UrlParameter.new(:name => @parm_name_dt.value, :value => @parm_value_dt.value)
         when /Cookie/i
           Watobo::CookieParameter.new(:name => @parm_name_dt.value, :value => @parm_value_dt.value)
          when /JSON/i
           Watobo::JSONParameter.new(:name => @parm_name_dt.value, :value => @parm_value_dt.value)
         else
           nil
         end
      end

    end

    class TableEditor < FXTable
      include Watobo::Subscriber
      def rawRequest
        parseRequest
      end
      
      def exportToClipboard
        entries = []
        self.numRows.times do |i|
          entry = []
          entry << self.getItemText(i, 1)
          entry << self.getItemText(i, 0)
          
          entry << self.getItemText(i, 2).unpack("C*").pack("C*").strip 
          entries << entry.join("|")
        end
        
        types = [ FXWindow.stringType ]
        if acquireClipboard(types)
          @clipboard_text = entries.join("\n")
        end        
      end

      def parseRequest
        return '' if @request.nil?
        request = @request.copy
        request.clear_parameters
        
        self.numRows.times do |i|
          #name = CGI.escape(self.getItemText(i, 1))
          #location = self.getItemText(i, 0)
          parm = self.getItemData(i, 0)
          parm.value = self.getItemText(i, 2).unpack("C*").pack("C*").strip 
          request.set parm
        end
        
        request
      end

      def setRequest(request)
        initTable()
        @request = nil
        return true if request.empty?
        @request = request.copy

        #return false if @request.content_type =~ /(multipart|json)/

        
        @request = Watobo::Utils.text2request(request) if request.is_a? String
        # addParmList("REQ", ["URL=#{request.url}"])

        @request.parameters.each do |parm|
          next unless parm.is_value?
          add_parm parm
        end

        true

      end

      def initialize(owner, opts)
        super(owner, opts)
        @request = nil
        @event_dispatcher_listeners = Hash.new
        initTable()

        self.connect(SEL_COMMAND, method(:onTableClick))

        # KEY_Return
        # KEY_Control_L
        # KEY_Control_R
        # KEY_s
        @ctrl_pressed = false

        addKeyHandler(self)
        
        @clipboard_text = ""
        self.connect(SEL_CLIPBOARD_REQUEST) do
        # setDNDData(FROM_CLIPBOARD, FXWindow.stringType, Fox.fxencodeStringData(@clipboard_text))
          setDNDData(FROM_CLIPBOARD, FXWindow.stringType, @clipboard_text + "\x00" )
        end

        self.connect(SEL_DOUBLECLICKED) do |sender, sel, data|
          row = sender.getCurrentRow
          if row >= 0 then
          self.selectRow(row, false)
          # open simple editor
          end
        end

        self.connect(SEL_DOUBLECLICKED) do |sender, sel, data|
          row = sender.getCurrentRow
          return nil unless row >= 0 and row < self.numRows
          transcoder = TranscoderWindow.new(FXApp.instance, self.getItemText(row, 2))
          transcoder.create
          transcoder.show(Fox::PLACEMENT_SCREEN)
        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            self.cancelInput()
            ypos = event.click_y
            row = self.rowAtY(ypos)

            next unless row >= 0 and row <= self.numRows

            self.selectRow(row, false) if row < self.numRows
            FXMenuPane.new(self) do |menu_pane|
              if row < self.numRows
                cell_value = self.getItemText(row, 2)
                cell_value.extend Watobo::Mixin::Transcoders

                parm_name = self.getItemText(row, 1)

                FXMenuCaption.new(menu_pane,"- Decoder -")
                FXMenuSeparator.new(menu_pane)
                decodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{cell_value.b64decode}")
                decodeB64.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.b64decode)
                }
                decodeHex = FXMenuCommand.new(menu_pane,"Hex(A): #{cell_value.hexdecode}")
                decodeHex.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.hexdecode)
                }
                hex2int = FXMenuCommand.new(menu_pane,"Hex(Int): #{cell_value.hex2int}")
                hex2int.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.hex2int)
                }
                decodeURL = FXMenuCommand.new(menu_pane,"URL: #{cell_value.url_decode}")
                decodeURL.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.url_decode)
                }

                FXMenuSeparator.new(menu_pane)
                FXMenuCaption.new(menu_pane,"- Encoder -")
                FXMenuSeparator.new(menu_pane)
                encodeB64 = FXMenuCommand.new(menu_pane,"Base64: #{cell_value.b64encode}")
                encodeB64.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.b64encode)
                }
                encodeHex = FXMenuCommand.new(menu_pane,"Hex: #{cell_value.hexencode}")
                encodeHex.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.hexencode)
                }
                encodeURL = FXMenuCommand.new(menu_pane,"URL: #{cell_value.url_encode}")
                encodeURL.connect(SEL_COMMAND) {
                  self.setItemText(row, 2, cell_value.url_encode)
                }
                
                 FXMenuSeparator.new(menu_pane)
                remRow = FXMenuCommand.new(menu_pane,"to Clipboard")
                remRow.connect(SEL_COMMAND) {
                  exportToClipboard
                }

                FXMenuSeparator.new(menu_pane)
                remRow = FXMenuCommand.new(menu_pane,"Remove: #{parm_name}")
                remRow.connect(SEL_COMMAND) {
                  self.removeRows(row,1, true)
                }
                remRow = FXMenuCommand.new(menu_pane,"Add Parameter..")
                remRow.connect(SEL_COMMAND) { addNewParm() }

              elsif row >= 0
                remRow = FXMenuCommand.new(menu_pane,"Add Parameter..")
                remRow.connect(SEL_COMMAND) { addNewParm() }
              end
              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)
            end

          end

        end

        self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
          self.fitColumnsToContents(index)
        end
      end

      private
      
      def add_parm(parm)
        lastRowIndex = self.getNumRows
          self.appendRows(1)
          self.setItemText(lastRowIndex, 0, parm.location.to_s)
          self.setItemData(lastRowIndex, 0, parm)
          n = parm.name.nil? ? "" : CGI.unescape(parm.name)
          self.setItemText(lastRowIndex, 1, n) 
          self.setItemText(lastRowIndex, 2, parm.value.to_s)
         
          3.times do |i|
            self.getItem(lastRowIndex, i).justify = FXTableItem::LEFT
            
            ct_len = self.getItemText(lastRowIndex, i).length
            ht_len = self.getColumnText(i).length
            self.fitColumnsToContents(i) if ct_len > ht_len
          end
      end

      def addNewParm()

        dlg = AddTableParmDialog.new(self)
        if dlg.execute != 0 then
          #loc = dlg.location
          #pname = dlg.parmName
          #pval = dlg.parmValue
          parm = dlg.param
          add_parm parm unless parm.nil?
        end
      end

      def onTableClick(sender, sel, item)
        begin
          row = item.row
          self.selectRow(row, false)
          self.startInput(row,2)
        rescue => bang
          puts bang
        end
      end

      def addKeyHandler(item)
        item.connect(SEL_KEYPRESS) do |sender, sel, event|
          cr = self.currentRow
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_F1
            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "<ctrl-enter> - Send Request",
                  "<ctrl-b> - Encode Base64",
                  "<ctrl-shift-b> - Decode Base64",
                  "<ctrl-u> - Encode URL",
                  "<ctrl-shift-u> - Decode URL"
                ].each do |hk|
                  FXMenuCaption.new(menu_pane, hk)
                end

                menu_pane.create

                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end
          end
          if @ctrl_pressed
            # special handling of KEY_Return, because we don't want a linebreak in textbox.
            if event.code == KEY_Return
              self.acceptInput(true)
              notify(:hotkey_ctrl_enter)
            true
            else
              notify(:hotkey_ctrl_f) if event.code == KEY_f
              notify(:hotkey_ctrl_s) if event.code == KEY_s
              
              text = self.getItemText(cr, 2).unpack("C*").pack("C*")

              if event.code == KEY_u
                cgi = CGI::escape(text)
              self.acceptInput(true)
              self.setItemText(cr, 2, cgi.strip, true)
              end

              if event.code == KEY_b
                #puts "* Encode B64: #{text}"
                b64 = Base64.strict_encode64(text)
                self.acceptInput(true)
                self.setItemText(cr, 2, b64.strip, true)
                puts b64.class
              end

             # puts "CTRL-SHIFT-U" if event.code == KEY_U
              if event.code == KEY_U
                uncgi = CGI::unescape(text)
              self.acceptInput(true)
              self.setItemText(cr, 2, uncgi.strip, true)
              end
              if event.code == KEY_B
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

      
      def initTable
        cws = []
        self.numColumns.times do |i|
          cws << self.getColumnWidth(i)
        end
        
        self.clearItems()
        self.setTableSize(0, 3)

        self.setColumnText( 0, "Location" )
        self.setColumnText( 1, "Parm" )
        self.setColumnText( 2, "Value" )
      
        self.rowHeader.width = 0
              
        cws.each_with_index do |w, i|
          self.setColumnWidth(i, w)
        end
      
      end

    end

    class TableEditorFrame < FXVerticalFrame
      def subscribe(event, &callback)
        @editor.subscribe event, &callback
      end
      
      def clear
        @editor.setRequest ''
        @req_line.text = ''
      end

      def setRequest(raw_request)
        if raw_request.is_a? String
          request = Watobo::Utils.text2request(raw_request)
        elsif raw_request.respond_to? :copy
          request = raw_request.copy
        else
          request = Watobo::Request.new raw_request
        end
       
        begin
        @editor.setRequest request
        @req_line.text = request.first.strip unless request.empty?
        return true
        rescue => bang
          puts bang
        end
        false

      end
      
      alias :setText :setRequest

      def initialize(owner, opts)
        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        #frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @req_line = FXText.new(self, :opts => LAYOUT_FILL_X|TEXT_FIXEDWRAP)
        @req_line.visibleRows = 1
        @req_line.backColor = @req_line.parent.backColor
        @req_line.disable
        @editor = TableEditor.new(self, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
      end
      
      def method_missing(name, *args, &block)
          
          if @editor.respond_to? name.to_sym
            return @editor.send(name.to_sym, *args, &block)
          else
            super
          end
        
      end
    end
  end
end

