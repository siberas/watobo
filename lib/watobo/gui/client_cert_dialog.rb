# @private
module Watobo#:nodoc: all
  module Gui
    class ClientCertDialog < FXDialogBox
      class PEMFrame < FXVerticalFrame
        def cert
          client_cert = {}

          begin
            if File.exist?(@client_cert_dt.value)
              client_cert[:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(@client_cert_dt.value))
            end

            if File.exist?(@client_key_dt.value)
              client_cert[:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(@client_key_dt.value), @password_dt.value)
            end

            return client_cert
          rescue => bang
            puts bang
            puts bang.backtrace
          end
          return nil
        end

        def settings
          s = {
            :certificate_file => @client_cert_dt.value,
            :password => @password_dt.value,
            :key_file => @client_key_dt.value
          }
        end

        def settings_valid?
          unless @password_dt.value.empty?
            puts "* password is set"
            if @password_dt.value != @retype_dt.value
              FXMessageBox.information(self, MBOX_OK, "Passwords", "Passwords don't match!")
            return false
            end
          password = @password_dt.value
          end

          unless File.exist?(@client_cert_dt.value)
            FXMessageBox.information(self, MBOX_OK, "File not found", "#{@client_cert_dt.value} does not exist!")
          return false
          end

          unless File.exist?(@client_key_dt.value)
            FXMessageBox.information(self, MBOX_OK, "File not found", "#{@client_key_dt.value} does not exist!")
          return false

          end
          # last but not least check if private key can be accessed
          begin
            key = OpenSSL::PKey::RSA.new(File.open(@client_key_dt.value), password)
          rescue => bang
            FXMessageBox.information(self, MBOX_OK, "Wrong Password", "Could not open private key file. Wrong password?")
          return false
          end
          true
        end

        def initialize(owner)
          @client_cert_dt = FXDataTarget.new('')
          @client_key_dt = FXDataTarget.new('')
          @password_dt = FXDataTarget.new('')
          @retype_dt = FXDataTarget.new('')

          super owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED
          matrix = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          FXLabel.new(matrix, "Certificate File:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @client_cert_txt = FXTextField.new(matrix,  25,
        :target => @client_cert_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

          FXButton.new(matrix, "Select").connect(SEL_COMMAND){ select_cert_file }

          FXLabel.new(matrix, "Key File:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @client_key_txt = FXTextField.new(matrix, 25,
        :target => @client_key_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
          FXButton.new(matrix, "Select").connect(SEL_COMMAND){ select_key_file }

          #  matrix = FXMatrix.new(main_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          FXLabel.new(matrix, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @password_txt = FXTextField.new(matrix, 25,
        :target => @password_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

          FXButton.new(matrix, "", :opts=>FRAME_NONE).disable

          FXLabel.new(matrix, "Retype:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @retype_txt = FXTextField.new(matrix, 25,
        :target => @retype_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

          FXButton.new(matrix, "", :opts=>FRAME_NONE).disable

        end

        private

        def select_cert_file()
          cert_filename = FXFileDialog.getOpenFilename(self, "Select Certificate File", @cert_path, "*.pem\n*")
          if cert_filename != "" then
            if File.exists?(cert_filename) then
              @client_cert_dt.value = cert_filename
              @client_cert_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @cert_path = File.dirname(cert_filename)
            end
          end
        end

        def select_key_file()

          key_filename = FXFileDialog.getOpenFilename(self, "Select Key File", @cert_path, "*.key\n*")
          if key_filename != "" then
            if File.exists?(key_filename) then
              @client_key_dt.value = key_filename
              @client_key_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @cert_path = File.dirname(key_filename)
            end
          end
        end

      end

      class PKCS12Frame < FXVerticalFrame
        def cert
          client_cert = {}
          password = @password_dt.value

          begin
puts "* open certfile: #{@client_cert_dt.value}"
            if File.exist?(@client_cert_dt.value)
              p12_data = nil
              File.open(@client_cert_dt.value, "rb"){|fh|
                p12_data = fh.read
              }
              p12 = OpenSSL::PKCS12.new( p12_data, password)
              puts p12.certificate
              client_cert[:ssl_client_cert] = p12.certificate
              client_cert[:ssl_client_key] = p12.key
              client_cert[:extra_chain_certs] =  p12.ca_certs

            end

            return client_cert
          rescue => bang
            puts bang
            puts bang.backtrace
          end
          return nil
        end

        def settings_valid?
          unless @password_dt.value.empty?
            puts "* password is set"
            if @password_dt.value != @retype_dt.value
              FXMessageBox.information(self, MBOX_OK, "Passwords", "Passwords don't match!")
            return false
            end
          password = @password_dt.value
          end

          unless File.exist?(@client_cert_dt.value)
            FXMessageBox.information(self, MBOX_OK, "File not found", "#{@client_cert_dt.value} does not exist!")
          return false
          end

          true
        end

        def settings
          s = {
            :certificate_file => @client_cert_dt.value,
            :password => @password_dt.value
          }
        end

        def initialize(owner)
          @client_cert_dt = FXDataTarget.new('')
          @client_key_dt = FXDataTarget.new('')
          @password_dt = FXDataTarget.new('')
          @retype_dt = FXDataTarget.new('')

          super owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED
          matrix = FXMatrix.new(self, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          FXLabel.new(matrix, "PKCS12 File:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @client_cert_txt = FXTextField.new(matrix,  25,
        :target => @client_cert_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

          FXButton.new(matrix, "Select").connect(SEL_COMMAND){ select_cert_file }

          FXLabel.new(matrix, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @password_txt = FXTextField.new(matrix, 25,
        :target => @password_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

          FXButton.new(matrix, "", :opts=>FRAME_NONE).disable

          FXLabel.new(matrix, "Retype:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @retype_txt = FXTextField.new(matrix, 25,
        :target => @retype_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

          FXButton.new(matrix, "", :opts=>FRAME_NONE).disable

        end

        private

        def select_cert_file()
          cert_filename = FXFileDialog.getOpenFilename(self, "Select Certificate File", @cert_path, "*.p12,*.pfx\n*")
          if cert_filename != "" then
            if File.exists?(cert_filename) then
              @client_cert_dt.value = cert_filename
              @client_cert_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @cert_path = File.dirname(cert_filename)
            end
          end
        end

      end

      class StoreFrame < FXVerticalFrame

      end

      NO_SELECTION = "no site selected"

      attr :client_certificates

      def savePasswords?()
        return false
      #@save_pws_cbt.checked?
      end

      include Responder

      def initialize(owner, prefs={})

        super(owner, "Client Certificates", :opts => DECOR_ALL)
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @password_policy = {
          :save_passwords => false
        }

        @cert_path = nil
        @client_certificates = {}

        current_certs = Watobo.project.getClientCertificates
        @client_certificates = current_certs unless current_certs.nil?

        @password_policy.update prefs[:password_policy] if prefs.has_key? :password_policy

        @site_dt = FXDataTarget.new('')

        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)

        @scope_only_cb = FXCheckButton.new(frame, "scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @scope_only_cb.setCheck(false)

        @scope_only_cb.connect(SEL_COMMAND) { updateSitesCombo() }

        @sites_combo = FXComboBox.new(frame, 5,  @site_dt, FXDataTarget::ID_VALUE,
        COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)

        @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
        @sites_combo.numColumns = 25
        @sites_combo.editable = true
        updateSitesCombo()

        @sites_combo.connect(SEL_COMMAND, method(:update_fields))

        # @save_pws_cbt = FXCheckButton.new(matrix, "save passwords")
        #  @save_pws_cbt.checkState = false
        #  @save_pws_cbt.checkState = true if @password_policy[:save_passwords] == true
        #  note_label = FXLabel.new(matrix, "This setting affects all passwords!!!")
        @cert_settings = []
        @tabBook = FXTabBook.new(main_frame, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        res_tab = FXTabItem.new(@tabBook, "PEM", nil)
        @cert_settings << PEMFrame.new(@tabBook)

        res_tab = FXTabItem.new(@tabBook, "PKCS12", nil)
        @cert_settings << PKCS12Frame.new(@tabBook)

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

      def updateSitesCombo()
        @sites_combo.clearItems
        @sites_combo.appendItem(NO_SELECTION, nil)
        @site_dt.value = NO_SELECTION
        Watobo::Chats.sites(:in_scope => @scope_only_cb.checked? ){ |site|
        #puts "Site: #{site}"
          @sites_combo.appendItem(site, site)
        }
        @sites_combo.numVisible = @sites_combo.numItems >= 20 ? 20 : @sites_combo.numItems
        @sites_combo.setCurrentItem(0, true) if @sites_combo.numItems > 0
        # @sites_combo.text = @sites_combo.getItemText(@sites_combo.currentItem)
        @sites_combo.handle(self, FXSEL(SEL_UPDATE, 1), nil)
      end

      def select_cert_file()
        cert_filename = FXFileDialog.getOpenFilename(self, "Select Certificate File", @cert_path)
        if cert_filename != "" then
          if File.exists?(cert_filename) then
            @client_cert_dt.value = cert_filename
            @client_cert_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @cert_path = File.dirname(cert_filename)
          end
        end
      end

      def updateFields()
        # @sites_combo.handle(self, FXSEL(SEL_UPDATE, 1), nil)
        @client_cert_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @client_key_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def update_fields(sender, sel, item)
        @site_dt.value = item
        if @client_certificates.has_key? item
          #puts "* certs found"
          #c = @client_certificates[item]
         # @client_cert_dt.value = c[:certificate_file]
         # @client_key_dt.value = c[:key_file]
         # @password_dt.value = c[:password]
         # @retype_dt.value = c[:password]
         # @client_cert_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
         # @client_key_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
         # @password_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
         # @retype_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end
      end

      def onAccept(sender, sel, event)

        password = nil
        if @site_dt.value.empty? or @site_dt.value == NO_SELECTION
          FXMessageBox.information(self, MBOX_OK, "No Site Selected", "You must select a site from the drop down list.")
        return 0
        end

        index = @tabBook.current
        unless @cert_settings[index].settings_valid?
          puts "Wrong settings"
        return 0
        end

        Watobo::ClientCertStore.set(@site_dt.value, @cert_settings[index].cert)

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end
    end
  end
end
