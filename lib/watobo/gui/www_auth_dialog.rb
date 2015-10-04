# @private 
module Watobo#:nodoc: all
  module Gui
    class AuthTable < FXTable
      include Watobo::Constants
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def settings
        www_auth = {}
        self.numRows.times do |i|
          www_auth_scope = Hash.new
          site = self.getItemText(i, 0)
          www_auth[site] = www_auth_scope
          www_auth_scope[:username] = self.getItemText(i, 2)
          www_auth_scope[:password] = self.getItemData(i, 3)
          www_auth_scope[:type] = self.getItemData(i, 1)
          www_auth_scope[:domain] = self.getItemText(i, 4)
          www_auth_scope[:workstation] = self.getItemText(i, 5)
        end
        www_auth
      end

      def delCurrentRow()
        cr = self.currentRow
        self.removeRows(cr, 1, true) if cr >= 0
        self.killSelection()
        notify(:item_selected, nil)
      end

      def addAuthScope(www_auth = {})
        return nil if www_auth[:username].nil? or www_auth[:password].nil?
        siteIndex = -1
        lastRowIndex = self.getNumRows
        lastRowIndex.times do |i|
          if self.getItemText(i, 0) == www_auth[:site] then
          siteIndex = i
          lastRowIndex = i
          break
          end
        end
        self.appendRows(1) if siteIndex < 0

        table_items = [ :site, :type, :username, :password, :domain, :workstation ]

        # puts table_items[i]
        self.setItemText(lastRowIndex, 0, www_auth[:site] )
        self.getItem(lastRowIndex, 0).justify = FXTableItem::LEFT

        text = case www_auth[:type]
        when AUTH_TYPE_NTLM
          "NTLM"
        end

        self.setItemText(lastRowIndex, 1,  text)
        self.setItemData(lastRowIndex, 1, www_auth[:type])
        self.getItem(lastRowIndex, 1).justify = FXTableItem::LEFT

        self.setItemText(lastRowIndex, 2, www_auth[:username] )
        self.getItem(lastRowIndex, 2).justify = FXTableItem::LEFT

        pw_text = www_auth[:password] == "" ? "- not set -" : "********"
        self.setItemText(lastRowIndex, 3, pw_text )
        self.setItemData(lastRowIndex, 3, www_auth[:password] )
        self.getItem(lastRowIndex, 3).justify = FXTableItem::LEFT

        self.setItemText(lastRowIndex, 4, www_auth[:domain] )
        self.getItem(lastRowIndex, 4).justify = FXTableItem::LEFT

        self.setItemText(lastRowIndex, 5, www_auth[:workstation] )
        self.getItem(lastRowIndex, 5).justify = FXTableItem::LEFT

      end

      def initialize(owner, opts)
        super(owner, opts)
        @event_dispatcher_listeners = Hash.new
        initTable()

        self.connect(SEL_COMMAND) { |sender, sel, item|
          cr = self.currentRow
          if cr >= 0 then
          www_auth = Hash.new
          www_auth_scope = Hash.new
          site = self.getItemText(cr, 0)
          www_auth[site] = www_auth_scope
          www_auth_scope[:username] = self.getItemText(cr, 2)
          www_auth_scope[:password] = self.getItemData(cr, 3)
          www_auth_scope[:type] = self.getItemData(cr, 1)
          www_auth_scope[:domain] = self.getItemText(cr, 4)
          www_auth_scope[:workstation] = self.getItemText(cr, 5)
          notify(:item_selected, www_auth)
          else
          notify(:item_selected, nil)
          end
        }

      end

      private

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def initTable()
        self.clearItems()
        self.setTableSize(0, 6)

        self.setColumnText( 0, "Site" )
        self.setColumnText( 1, "Type" )
        self.setColumnText( 2, "User" )
        self.setColumnText( 3, "Password" )
        self.setColumnText( 4, "Domain" )
        self.setColumnText( 5, "Workstation" )

        self.rowHeader.width = 0

        col_width = [ 80, 80, 80, 80, 80, 80 ]
        col_width.length.times do |i|
          self.setColumnWidth(i, col_width[i])
        end

        notify(:item_selected, false)
      end
    end

    class WwwAuthDialog < FXDialogBox

      include Watobo::Gui::Icons
      include Watobo::Constants

      NO_SELECTION = "no site selected"
      def savePasswords?()
        return false
        #@save_pws_cbt.checked?
      end

      include Responder

      def initialize(owner)

        super(owner, "NTLM Authentication", :opts => DECOR_ALL)
        @project = Watobo.project
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

     #   @password_policy = {
     #     :save_passwords => false
     #   }

      #  @password_policy.update prefs[:password_policy] if prefs.has_key? :password_policy

        @site_dt = FXDataTarget.new('')
        @username_dt = FXDataTarget.new('')
        @domain_dt = FXDataTarget.new('')
        @password_dt = FXDataTarget.new('')
        @workstation_dt = FXDataTarget.new('')
        @auth_type_dt = FXDataTarget.new(AUTH_TYPE_NTLM)

        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        top_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)

      #  @scope_only_cb = FXCheckButton.new(top_frame, "scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
      #  @scope_only_cb.setCheck(false)

      #  if project.has_scope?
      #  puts "project has scope defined"
      #  end
       # @scope_only_cb.connect(SEL_COMMAND) { updateSitesCombo() }

        @sites_combo = FXComboBox.new(top_frame, 5,  @site_dt, FXDataTarget::ID_VALUE,
        COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

        @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
        @sites_combo.numColumns = 25
        @sites_combo.editable = true
        updateSitesCombo()

        FXLabel.new(top_frame, "User:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @username_txt = FXTextField.new(top_frame, 10,
        :target => @username_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        FXLabel.new(top_frame, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @password_txt = FXTextField.new(top_frame, 10,
        :target => @password_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

        FXLabel.new(top_frame, "Domain:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @domain_txt = FXTextField.new(top_frame, 10,
        :target => @domain_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        FXLabel.new(top_frame, "Workstation:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @workstation_txt = FXTextField.new(top_frame, 10,
        :target => @workstation_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

        table_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        @auth_table = AuthTable.new(table_frame, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY)

        @auth_table.subscribe(:item_selected){ |selection|
          unless selection.nil? then
            @rem_auth_btn.enable
            selection.each_key do |k|
              settings = selection[k]
              @site_dt.value = k
              @sites_combo.setText(k)
              @username_dt.value = settings[:username]
              # @password_dt.value = settings[:password]
              @domain_dt.value = settings[:domain]
              @workstation_dt.value = settings[:workstation]
              updateFields()
            end
          else
          @rem_auth_btn.disable
          end
        }

        #pas = @project.getWwwAuthentication()
        pas = Watobo::Conf::Scanner.www_auth
        #   puts pas.to_yaml
        pas.each_key do |k|
          auth_settings = {
            :username => pas[k][:username],
            :password => pas[k][:password],
            :domain => pas[k][:domain],
            :workstation => pas[k][:workstation],
            :site => k,
            :type => pas[k][:type]
          }
          @auth_table.addAuthScope(auth_settings)
        end

        table_btn_frame = FXVerticalFrame.new(table_frame, :opts => LAYOUT_FILL_Y|PACK_UNIFORM_WIDTH)
        @add_auth_btn = FXButton.new(table_btn_frame, "Add")
        @add_auth_btn.connect(SEL_COMMAND){ addAuthenticationItem() }
        #@add_auth_btn.disable

        @rem_auth_btn = FXButton.new(table_btn_frame, "Remove")
        @rem_auth_btn.connect(SEL_COMMAND){ remAuthenticationItem() }
        @rem_auth_btn.disable

      #  frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
      #  @save_pws_cbt = FXCheckButton.new(frame, "save passwords")
      #  @save_pws_cbt.checkState = false
      #  @save_pws_cbt.checkState = true if @password_policy[:save_passwords] == true
      #  note_label = FXLabel.new(frame, "This setting affects all passwords!!!")

        buttons = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        accept.enable
        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end

      private

      def remAuthenticationItem()
        @auth_table.delCurrentRow()
      end

      def updateSitesCombo()
        @sites_combo.clearItems
        @sites_combo.appendItem(NO_SELECTION, nil)
        unless Watobo.project.nil?
        Watobo::Chats.sites(:in_scope => Watobo::Scope.exist? ){ |site|
        #puts "Site: #{site}"
          @sites_combo.appendItem(site, site)
        }
        end
        @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
        @sites_combo.setCurrentItem(0) if @sites_combo.numItems > 0
      end

      def addAuthenticationItem()
        ci = @sites_combo.currentItem
        site = @site_dt.value
        #  site = ( ci >= 0 ) ? @sites_combo.getItemData(ci) : nil
        return nil if site == NO_SELECTION
        auth_settings = {
          :username => @username_dt.value,
          :password => @password_dt.value,
          :domain => @domain_dt.value,
          :workstation => @workstation_dt.value,
          :site => site,
          :type => AUTH_TYPE_NTLM
        }

        @auth_table.addAuthScope(auth_settings)

      end

      def updateFields()
        # @sites_combo.handle(self, FXSEL(SEL_UPDATE, 1), nil)
        @username_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @password_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @workstation_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @domain_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def onAccept(sender, sel, event)
        settings = @auth_table.settings
        empty_passwords = false
        settings.each_key do |w3a|
          empty_passwords = true if settings[w3a][:password] == ''
        end
        unless empty_passwords == true then
        Watobo::Conf::Scanner.www_auth = @auth_table.settings
        #  puts @auth_table.settings.to_yaml
        getApp().stopModal(self, 1)
        self.hide()
        return 1
        else
        FXMessageBox.information(self, MBOX_OK, "Empty Passwords", "You must enter a password!")
        end

      end
    end

  end
end
