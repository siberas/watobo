# @private
module Watobo#:nodoc: all
  module Gui
    class AddProxyDialog < FXDialogBox

      include Responder
      include Watobo::Constants
      def getProxySettings
        s = {
          :name =>  @proxy_name_dt.value,
          :port => @proxy_port_dt.value,
          :host => @proxy_dt.value,
          :target_pattern => @pattern_dt.value,
          :enabled => true
        }

        c = {
          :username => @username_dt.value,
          :password => @password_dt.value,
          :workstation => @workstation_dt.value,
          :domain => @domain_dt.value,
          :auth_type => @auth_type
        }

        puts "* auth_type"
        puts c[:auth_type]
        if @auth_types_cb.currentItem > 0 and c[:username] != "" and c[:password] != ""
        s.update c
        end

        return s

      end

      def savePasswords?()
        return false
      # @save_pws_cbt.checked?
      end

      def onAccept(sender, sel, event)
        if @proxy_dt.value != "" then
          begin
            proxy_ip = IPSocket.getaddress(@proxy_dt.value)
          rescue
            FXMessageBox.information(self, MBOX_OK, "Wrong Host", "Could not resolve hostname #{@proxy_dt.value}")
          return 0
          end
        else
          FXMessageBox.information(self, MBOX_OK, "No Proxy", "You need to set the proxy host")
        return 0
        end

        unless @proxy_port_dt.value =~ /^\d{1,5}$/ then
          FXMessageBox.information(self, MBOX_OK, "Wrong Format", "Port format is wrong (e.g. 8080")
        return 0
        end

        if @auth_type != AUTH_TYPE_NONE

          unless @password_dt.value == @password_rt_dt.value then
            FXMessageBox.information(self, MBOX_OK, "Password Missmatch", "Passwords don't match!")
          return 0
          end

          unless @password_dt.value != ''
            FXMessageBox.information(self, MBOX_OK, "No Password!", "You need a password!")
          return 0
          end
        end

        if @proxy_name_dt.value == ""
          FXMessageBox.information(self, MBOX_OK, "Proxy Name Missing", "You need to set a name for the new proxy (e.g. myproxy)")
        return 0
        end

        #  @password_policy[:save_passwords] = @save_pws_cbt.checked?
        #  puts @password_policy.to_yaml
        getApp().stopModal(self, 1)
        self.hide()
        return 1

      end

      def initialize(owner, proxy=nil)

        super(owner, "Proxy Settings", :opts => DECOR_TITLE|DECOR_BORDER)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @proxy_name_dt = FXDataTarget.new('')
        @proxy_port_dt = FXDataTarget.new('')
        @proxy_dt = FXDataTarget.new('')
        @pattern_dt = FXDataTarget.new('')
        @username_dt = FXDataTarget.new('')
        @password_dt = FXDataTarget.new('')
        @password_rt_dt = FXDataTarget.new('')
        @workstation_dt = FXDataTarget.new('')
        @domain_dt = FXDataTarget.new('')
        @auth_type_dt = FXDataTarget.new(AUTH_TYPE_NTLM)

        unless proxy.nil?
          begin
            puts proxy.to_yaml
            @proxy_name_dt.value = proxy[:name]
            @proxy_port_dt.value = proxy[:port]
            @proxy_dt.value = proxy[:host]
            @pattern_dt.value = proxy[:target_pattern]

            @username_dt.value = proxy[:username] if proxy.has_key? :username
            @password_dt.value = proxy[:password] if proxy.has_key? :password
            @password_rt_dt.value = proxy[:password] if proxy.has_key? :password
            @workstation_dt.value = proxy[:workstation] if proxy.has_key? :workstation
            @domain_dt.value = proxy[:domain] if proxy.has_key? :domain
            @auth_type_dt.value = proxy[:auth_type] if proxy.has_key? :auth_type
          rescue => bang
            puts bang
          end

        end

        # @password_policy = Hash.new
        # @password_policy.update password_policy
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        matrix = FXMatrix.new(main, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        FXLabel.new(matrix, "Name:", nil, :opts => LAYOUT_TOP|JUSTIFY_RIGHT)
        proxy_name = FXTextField.new(matrix, 25,
        :target => @proxy_name_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        proxy_name.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(matrix, "Hostname/IP:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)

        hostname = FXTextField.new(matrix, 25,
        :target => @proxy_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
        hostname.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(matrix, "Port:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        port = FXTextField.new(matrix, 25,
        :target => @proxy_port_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        port.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        
        
        FXLabel.new(matrix, "Pattern:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        pattern = FXTextField.new(matrix, 25,
        :target => @pattern_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        pattern.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(matrix, "Auth-Type:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @auth_types_cb = FXComboBox.new(matrix, 5, nil, 0,
        COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        #@filterCombo.width =200
        auth_types = ['None', 'NTLM']
        @auth_types_cb.numVisible = auth_types.length
        @auth_types_cb.numColumns = 25
        @auth_types_cb.editable = false
        auth_types.each do |at|
          @auth_types_cb.appendItem(at, nil)
        end
        @auth_types_cb.setCurrentItem(0)

        unless proxy.nil?
          if proxy.has_key?(:auth_type)
            case proxy[:auth_type]
            when AUTH_TYPE_NTLM
              @auth_types_cb.setCurrentItem(1)
            end
          end
        end

        @auth_types_cb.connect(SEL_COMMAND){
          updateCredFrame()
        }

        @credentials_frame = FXMatrix.new(main, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        FXLabel.new(@credentials_frame, "Username:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        username = FXTextField.new(@credentials_frame, 25,
        :target => @username_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
        username.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(@credentials_frame, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        password = FXTextField.new(@credentials_frame, 25,
        :target => @password_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)
        password.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(@credentials_frame, "Password(retype):", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        password = FXTextField.new(@credentials_frame, 25,
        :target => @password_rt_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)
        password.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(@credentials_frame, "Workstation:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        workstation = FXTextField.new(@credentials_frame, 25,
        :target => @workstation_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
        workstation.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        FXLabel.new(@credentials_frame, "Domain:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        domain = FXTextField.new(@credentials_frame, 25,
        :target => @domain_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
        domain.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        #  frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X)
        #  @save_pws_cbt = FXCheckButton.new(frame, "save passwords")
        #  @save_pws_cbt.checkState = false
        #  @save_pws_cbt.checkState = true if password_policy[:save_passwords] == true
        #  note_label = FXLabel.new(frame, "This setting affects all passwords!!!")

        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        accept.enable
        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        updateCredFrame()
      end
      private

      def updateCredFrame()
        ci = @auth_types_cb.currentItem

        @auth_type = case ci
        when 0
          AUTH_TYPE_NONE
        when 1
          AUTH_TYPE_NTLM
        else
        AUTH_TYPE_NONE
        end
        @credentials_frame.each_child do |c|
          if c.is_a? FXTextField
            if ci > 0
              c.backColor = FXColor::White
            c.enable
            else
            c.backColor = c.parent.backColor
            c.disable
            end
          end
        end
      end
    end

    class ProxyDialog < FXDialogBox
      #TODO: Implement Connection Check!!

      attr_accessor :proxy

      include Responder
      def switchEnableProxy()
        @proxyTable.show()
        @newProxyButton.enable
        selectProxy(@proxy)
        @acceptBtn.disable
        refreshProxyList()
        
        @proxySelectionFrame.enable
        #@proxy_prelabel.enable
        #@proxy_label.enable
      end

      def refreshProxyList
        @proxyTable.clearItems(false)
        @proxyTable.setTableSize(0, 4)
        @proxyTable.setColumnText(0, "Name" )
        @proxyTable.setColumnText(1, "Proxy" )
        @proxyTable.setColumnText(2, "Pattern" )
        @proxyTable.setColumnText(3, "Enabled" )
        return if @proxy_list.nil?
        @proxy_list.each_key do |proxy|
          puts "* addProxyItem #{proxy}"
          addProxyItem(@proxy_list[proxy])
        end
      end

      def getProxyPrefs()
       # @proxy_list[:default_proxy] = @proxy.nil? ? '' : @proxy[:name]
        @proxy_list
      end

      def onAccept(sender, sel, event)
        # @settings[:proxies] = proxies
        @proxy_list = Hash.new
        lastRowIndex = @proxyTable.numRows
        lastRowIndex.times do |i|
          proxy = @proxyTable.getItemData(i,0)
          # puts proxy.to_yaml
          @proxy_list[proxy[:name]] = proxy
        end
        #  @password_policy[:save_passwords] = @save_passwords
        getApp().stopModal(self, 1)
        self.hide()
        return 1

      end

      def onCancel(sender, sel, event)
        getApp().stopModal(self, 0)
        self.hide()
        return 1
      end

      def addProxy(proxy=nil)
        pdlg = AddProxyDialog.new(self, proxy)

        if pdlg.execute != 0
          @acceptBtn.enable
          @acceptBtn.setFocus()
          @acceptBtn.setDefault()

          last = @proxyTable.getNumRows
          @proxy = pdlg.getProxySettings
          @save_passwords = pdlg.savePasswords?
          @proxy_list[@proxy[:name]] = @proxy

          addProxyItem( @proxy )

          lastRowIndex = @proxyTable.numRows
          last = -1
          lastRowIndex.times do |i|
            if @proxyTable.getItemText(i, 0) == @proxy[:name] then
            last = i
            break
            end
          end
          return -1 if last == -1

          @proxyTable.selectRow(last)
          @proxyTable.makePositionVisible(last,0)
         # @proxy_label.text = @proxy[:name]
        end
      end

      def delProxy(sender, sel, event)

        row = @proxyTable.getCurrentRow
        #  puts row
        if row >= 0 and @proxyTable.rowSelected?(row) then
          p = @proxyTable.getItem(row,1).to_s
          #puts @proxy.class.to_s
          #   puts "delete: #{proxy}"
          @proxy = ''
          @proxyTable.removeRows(row,1)
          @proxyTable.killSelection(true)
          @delProxyButton.disable
          #@acceptBtn.disable
         # @proxy_label.text = ''
        end
      end

      def editProxy()
        row = @proxyTable.getCurrentRow
        puts row
        if row >= 0 and @proxyTable.rowSelected?(row) then
          #p = @proxyTable.getItem(row,1).to_s
          proxy = @proxyTable.getItemData(row,0)
          addProxy(proxy)
        end
      end

      def onProxySelect(sender, sel, index)

        row = sender.getCurrentRow
        if row >= 0 then
          @proxyTable.selectRow(row)
          @proxy = @proxyTable.getItemData(row,0)
          #@proxy_label.text = @proxy[:name]
        @delProxyButton.enable
        @editProxyButton.enable
        @acceptBtn.enable
        @acceptBtn.setFocus()
        @acceptBtn.setDefault()
        end
      end

      def selectProxy(proxy={})
        @editProxyButton.disable
        @delProxyButton.disable
        @proxyTable.killSelection(true)
       # @proxy_label.text = "- none -"
        @proxy = nil
        return false if proxy.nil?
        return false unless proxy[:name]
        proxy_name = proxy[:name]
        i = 0
        @proxyTable.each do |items|
          if items[0].to_s == proxy_name
            puts "* match #{proxy_name}"
            @proxyTable.selectRow(i)
            @proxyTable.setCurrentItem(i,0)
            @proxyTable.makePositionVisible(i,0)
            @proxy = @proxyTable.getItemData(i,0)
          #  puts @proxy
          #@proxy_label.text = proxy_name
          @delProxyButton.enable
          end
          i += 1
        end
        unless @proxy.nil?
        @editProxyButton.enable
        @delProxyButton.enable
        end
      end

      def addProxyItem(proxy)
        # puts proxy.to_yaml
        lastRowIndex = @proxyTable.numRows
        siteIndex = -1
        lastRowIndex.times do |i|
          if @proxyTable.getItemText(i, 0) == proxy[:name] then
          siteIndex = i
          lastRowIndex = i
          break
          end
        end
        @proxyTable.appendRows(1) if siteIndex < 0

        @proxyTable.rowHeader.setItemJustify(lastRowIndex,FXTableItem::LEFT)
        @proxyTable.setItemText(lastRowIndex, 0, proxy[:name])
        @proxyTable.getItem(lastRowIndex,0).justify = FXTableItem::LEFT
        @proxyTable.setItemText(lastRowIndex, 1, proxy[:host] + ":" + proxy[:port])
        @proxyTable.setItemData(lastRowIndex, 0, proxy)
        @proxyTable.getItem(lastRowIndex,1).justify = FXTableItem::LEFT

        @proxyTable.setItemText(lastRowIndex, 2, proxy[:target_pattern])
        #@proxyTable.setItemData(lastRowIndex, 0, proxy)
        @proxyTable.getItem(lastRowIndex,2).justify = FXTableItem::LEFT

        enabled = proxy[:enabled] ? "True" : "False"
        @proxyTable.setItemText(lastRowIndex, 3, enabled)
        #@proxyTable.setItemData(lastRowIndex, 0, proxy)
        @proxyTable.getItem(lastRowIndex,3).justify = FXTableItem::LEFT
      end

      def initialize(owner)
        super(owner, "Use Proxy", :opts => DECOR_ALL, :width => 450, :height => 400)
        @new_proxy = FXDataTarget.new('')
        @save_passwords = false

        @proxy_settings = Hash.new
        @proxy_settings.update(Watobo::Conf::ForwardingProxy.to_h)

        #  @password_policy = password_policy

        @proxy = nil
        pname = @proxy_settings[:default_proxy]
        @proxy_settings ||= {}
        if @proxy_settings.has_key? pname
          @proxy = @proxy_settings[pname]
        end

        @proxy_list = {}
        @proxy_list.update YAML.load(YAML.dump(@proxy_settings))
        @proxy_list.delete(:default_proxy)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        FXMAPFUNC(SEL_COMMAND, ID_CANCEL, :onCancel)

       # current_proxy_frame = FXHorizontalFrame.new(self,FRAME_NONE|LAYOUT_FILL_X|FRAME_GROOVE)
       # FXLabel.new(current_proxy_frame, "Current Proxy:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
       # @cp_label = FXLabel.new(current_proxy_frame, "- none -", nil, LAYOUT_TOP|JUSTIFY_RIGHT)

        main_frame = FXVerticalFrame.new(self, :opts => FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        enable_proxy_frame = FXHorizontalFrame.new(main_frame,FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y)
       # @proxyEnableCheckButton = FXCheckButton.new(enable_proxy_frame, "enable forwarding proxy", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        FXLabel.new(enable_proxy_frame, "Right click row for enabling/disabling proxy.")

       # @proxyEnableCheckButton.connect(SEL_COMMAND) do |sender, sel, item|
       #   switchEnableProxy()
       # end

        @proxySelectionFrame = FXGroupBox.new(main_frame, "Select Forwarding Proxy", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)

        proxySubSelection = FXVerticalFrame.new(@proxySelectionFrame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        @proxyTable = FXTable.new(proxySubSelection,
        :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY,
        :padding => 2)
        @proxyTable.setTableSize(0, 4)

        @proxyTable.connect(SEL_COMMAND, method(:onProxySelect))
        @proxyTable.connect(SEL_SELECTED, method(:onProxySelect))

        @proxyTable.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            #   row = sender.getCurrentRow
            ypos = event.click_y
            row = @proxyTable.rowAtY(ypos)
            #  puts "right click on row #{row} of #{@chatTable.numRows}"
            if row >= 0 and row < @proxyTable.numRows then
              proxy = @proxyTable.getItemData(row,0)

              @proxyTable.selectRow(row, false)
              FXMenuPane.new(self) do |menu_pane|
                target = FXMenuCheck.new(menu_pane, "Enabled" )
                target.check = proxy.has_key?(:enabled) ? proxy[:enabled] : false
                target.connect(SEL_COMMAND) {
                  proxy[:enabled] = target.checked?()
                  refreshProxyList
                }

                menu_pane.create
                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end
          end
        end

        @proxyTable.rowHeaderWidth = 0
        @proxyTable.rowHeaderMode = LAYOUT_FIX_WIDTH

        @proxyTable.visibleRows = 5
        @proxyTable.setColumnText(0, "Name" )
        @proxyTable.setColumnText(1, "Proxy" )

        buttons_frame = FXHorizontalFrame.new( proxySubSelection, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @newProxyButton = FXButton.new(buttons_frame, "Add" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @newProxyButton.connect(SEL_COMMAND){ addProxy() }

        @editProxyButton = FXButton.new(buttons_frame, "Edit" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @editProxyButton.connect(SEL_COMMAND) { editProxy() }
        @editProxyButton.disable

        @delProxyButton = FXButton.new(buttons_frame, "Delete" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @delProxyButton.connect(SEL_COMMAND, method(:delProxy))
        @delProxyButton.disable

       # selection_frame = FXHorizontalFrame.new(main_frame,FRAME_NONE|LAYOUT_FILL_X)
       # @proxy_prelabel = FXLabel.new(selection_frame, "Selected Proxy:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
       # @proxy_label = FXLabel.new(selection_frame, "- none -", nil, LAYOUT_TOP|JUSTIFY_RIGHT)

        buttons = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        # Accept
        @acceptBtn = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        @acceptBtn.enable
        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        #@proxyEnableCheckButton.setCheck(false, false)
        #@proxyEnableCheckButton.setCheck(true, false) unless @proxy.nil?
        refreshProxyList()
        switchEnableProxy()

        unless @proxy.nil?
          @cp_label.text = @proxy[:name]
          selectProxy(@proxy)
        end

      end
    end

  end
end
