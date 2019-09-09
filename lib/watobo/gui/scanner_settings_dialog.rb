# @private 
module Watobo#:nodoc: all
  module Gui
    
    class ScannerSettingsFrame < FXVerticalFrame
      
      def getSettings()
        settings = Hash.new
        settings[:max_parallel_checks] = @max_par_checks.value
        settings[:smart_scan] = @enable_smart_scan.checked?
        settings[:run_passive_checks] = @enable_passive_checks.checked?
        settings[:ignore_server_errors] = @ignore_server_errors.checked?
        
        settings[:scanlog_dir] = ''
        if @log_scan_cb.checked? then
        settings[:scanlog_dir] = @scanlog_dir_dt.value  
        end
        
        dummy = []
        @nup_list.each do |nup|
          dummy.push nup.data
        end
        settings[:non_unique_parms] = dummy
        
        dummy = []
        @exp_list.each do |exp|
          dummy.push exp.data
        end
        settings[:excluded_parms] = dummy
        
        dummy = []
        @cep_list.each do |exp|
          dummy.push exp.data
        end
        settings[:custom_error_patterns] = dummy

        settings[:dns_sensor] = @dns_dt.value.strip

        puts 'Scanner Settings:'
        puts settings.to_json
        puts '---'
        return settings
      end
      
      def addItem(list_box, item)   
        if item != "" then
          list_item = list_box.appendItem("#{item}")
          list_box.setItemData(list_item, item)
          list_box.sortItems()        
        end
      end
      
      def selectScanlogDirectory(sender, sel, item)
        workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Scanlog Directory", @scanlog_dir_dt.value)
        if workspace_dt != "" then
          if File.exist?(workspace_dt) then
            @scanlog_dir_dt.value = workspace_dt
            @scanlog_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end
        end
      end
      
      def removePattern(list_box)
        index = list_box.currentItem
        #puts index
        if  index >= 0
          list_box.removeItem(index)
        end
      end
      
    #  def initialize(owner, scan_settings, opts)        
      def initialize(owner, opts)
        super(owner, opts)
        
        @settings = Watobo::Conf::Scanner.to_h
       # puts @settings[:scanlog_dir]
        scroller = FXScrollWindow.new(self, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_area = FXVerticalFrame.new(scroller, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        gbox = FXGroupBox.new(scroll_area, "Request Limit", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        gbox_frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_SIDE_TOP|PACK_UNIFORM_WIDTH)
        FXLabel.new(gbox_frame, "Maximum limit of parallel requests.")
        frame = FXHorizontalFrame.new(gbox_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Max. Par. Request:")
        @max_par_checks = FXDataTarget.new(0)
        @max_par_checks.value = @settings[:max_parallel_checks]
        mpc = FXTextField.new(frame, 3, @max_par_checks, FXDataTarget::ID_VALUE, :opts => JUSTIFY_RIGHT|FRAME_GROOVE|FRAME_SUNKEN)
        mpc.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        
        gbox = FXGroupBox.new(scroll_area, "Smart Scan ", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 80)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        @enable_smart_scan = FXCheckButton.new(frame, "Enable Smart Scan ", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @enable_smart_scan.checkState = @settings[:smart_scan]
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "If Smart Scan is enabled the scanner will reduce the number of checks."
        fxtext.setText(text)


        gbox = FXGroupBox.new(scroll_area, "DNS Sensor", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 80)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "IP address or hostname of DNS sensor. The sensor is used to recognize DNS request originated from the target system, which might be forced by some checks."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X)
        @dns_dt = FXDataTarget.new('')
        @dns_dt.value = ( @settings.has_key?(:dns_sensor) ? @settings[:dns_sensor] : 'localhost' )
        @dns_field = FXTextField.new(input_frame, 20, :target => @dns_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @reset_dns_btn = FXButton.new(input_frame, "Reset" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

        @reset_dns_btn.connect(SEL_COMMAND){ |sender, sel, item|
          @dns_dt.value = 'localhost'
          @dns_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }


       #@edit_uniq_parms_btn = FXButton.new(frame, "Non-Unique Parms", :opts => LAYOUT_RIGHT|FRAME_RAISED)
        
        fxtext = FXText.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable

        
        gbox = FXGroupBox.new(scroll_area, "Response Codes", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 50)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        @ignore_server_errors = FXCheckButton.new(frame, "Ignore Server Errors ", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @ignore_server_errors.checkState = @settings[:ignore_server_errors]
        
        #@edit_uniq_parms_btn = FXButton.new(frame, "Non-Unique Parms", :opts => LAYOUT_RIGHT|FRAME_RAISED)
        
        fxtext = FXText.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Handle error codes (5xx) as file does not exist"
        fxtext.setText(text)
        
        
        gbox = FXGroupBox.new(scroll_area, "Passive Checks", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 150)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        @enable_passive_checks = FXCheckButton.new(frame, "Enable Passive Checks", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @enable_passive_checks.checkState = @settings[:run_passive_checks]
        fxtext = FXText.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Run Passive Checks on each single test request.\nWARNING!!!\nThis may produce a lot of False Positive Results."
        fxtext.setText(text)
        
        
        
        gbframe = FXGroupBox.new(scroll_area, "Non-Unique-Parameters", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Parameters which have a special function should be ignored for smart-scanning, e.g. if you app has parms like 'action=AddUser' or 'action=DeleteUser' you should add 'action' to this list."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @nup_dt = FXDataTarget.new('')
        @nup_field = FXTextField.new(input_frame, 20, :target => @nup_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_nup_btn = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @add_nup_btn = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @nup_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @nup_list.numVisible = 5
        
        @nup_list.connect(SEL_COMMAND){ |sender, sel, item|
          @nup_dt.value = sender.getItemText(item)
          @nup_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @settings[:non_unique_parms].each do |nup|
          addItem(@nup_list, nup)
        end
        
        @rem_nup_btn.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@nup_list) if @nup_dt.value != ''
          @nup_dt.value = ''
          @nup_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @add_nup_btn.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@nup_list, @nup_dt.value) if @nup_dt.value != ''
          @nup_dt.value = ''
          @nup_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @nup_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@nup_list, @nup_dt.value) if @nup_dt.value != ''
          @nup_dt.value = ''
          @nup_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        
        @exp_dt = FXDataTarget.new('')
        exp_frame = FXGroupBox.new(scroll_area, "Excluded Parameters", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(exp_frame, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Parameters which should not be tested during a scan."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @exp_dt = FXDataTarget.new('')
        @exp_field = FXTextField.new(input_frame, 20, :target => @exp_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_exp_btn = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @add_exp_btn = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @exp_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @exp_list.numVisible = 5
        
        @settings[:excluded_parms].each do |exp|
          addItem(@exp_list, exp)
        end
        
        @exp_list.connect(SEL_COMMAND){ |sender, sel, item|
          @exp_dt.value = sender.getItemText(item)
          @exp_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @rem_exp_btn.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@exp_list) if @exp_dt.value != ''
          @exp_dt.value = ''
          @exp_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @add_exp_btn.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@exp_list, @exp_dt.value) if @exp_dt.value != ''
          @exp_dt.value = ''
          @exp_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @exp_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@exp_list, @exp_dt.value) if @exp_dt.value != ''
          @exp_dt.value = ''
          @exp_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        #############################################################
        @cep_dt = FXDataTarget.new('')
        cep_frame = FXGroupBox.new(scroll_area, "Custom Error Pages", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(cep_frame, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regex-Pattern to identify custom error pages. Header and Body will be checked."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @cep_dt = FXDataTarget.new('')
        @cep_field = FXTextField.new(input_frame, 20, :target => @cep_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_cep_btn = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @add_cep_btn = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @cep_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @cep_list.numVisible = 5
        
        @settings[:custom_error_patterns].each do |exp|
          addItem(@cep_list, exp)
        end
        
        @cep_list.connect(SEL_COMMAND){ |sender, sel, item|
          @cep_dt.value = sender.getItemText(item)
          @cep_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @rem_cep_btn.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@cep_list) if @cep_dt.value != ''
          @cep_dt.value = ''
          @cep_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @add_cep_btn.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@cep_list, @cep_dt.value) if @cep_dt.value != ''
          @cep_dt.value = ''
          @cep_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @cep_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@cep_list, @cep_dt.value) if @cep_dt.value != ''
          @cep_dt.value = ''
          @cep_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        #############################################################
        
        gbox = FXGroupBox.new(scroll_area, "Logging", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 150)
        scan_opt_frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @log_scan_cb = FXCheckButton.new(scan_opt_frame, "Log Scan", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @log_scan_cb.checkState = false
        @log_scan_cb.connect(SEL_COMMAND) do |sender, sel, item|
          if @log_scan_cb.checked? then
            @scanlog_dir_text.enabled = true
            @scanlog_dir_label.enabled = true
            @scanlog_dir_btn.enable
          else
            @scanlog_dir_text.enabled = false
            @scanlog_dir_label.enabled = false
            @scanlog_dir_btn.disable
          end
        end
        
        
        @scanlog_dir_dt = FXDataTarget.new('')
        unless @settings[:scanlog_dir].nil? then @scanlog_dir_dt.value = @settings[:scanlog_dir] if File.exist?(@settings[:scanlog_dir]); end
        @scanlog_dir_label = FXLabel.new(scan_opt_frame, "Scan-Log Directory:" )
        scanlog_frame = FXHorizontalFrame.new(scan_opt_frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        @scanlog_dir_text = FXTextField.new(scanlog_frame, 20,
                                            :target => @scanlog_dir_dt, :selector => FXDataTarget::ID_VALUE,
                                            :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
        @scanlog_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @scanlog_dir_btn = FXButton.new(scanlog_frame, "Change")
        @scanlog_dir_btn.connect(SEL_COMMAND, method(:selectScanlogDirectory))
        
        @scanlog_dir_text.enabled = false
        @scanlog_dir_label.enabled = false
        @scanlog_dir_btn.disable
      end
      
    end
    
    #
    # Class: SelectNonUniqueParmsDialog
    #
    class ScannerSettingsDialog < FXDialogBox
      
      include Responder
      attr :scanner_settings
      
      
      def onAccept(sender, sel, event)
        
        new_settings = Watobo::Conf::Scanner.to_h
        new_settings.update @scannerSettingsFrame.getSettings()
        Watobo::Conf::Scanner.set new_settings

        Watobo::Gui.save_scanner_settings

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end
      
     
      
      def initialize(owner, prefs)
        super(owner, "Scanner Settings", DECOR_TITLE|DECOR_BORDER, :width => 400, :height => 500)
       # @scanner_settings = scanner_settings
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        
        
        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        #  puts "create scopeframe with scope:"
        # @project.scope
        # @defineScopeFrame = DefineScopeFrame.new(base_frame, Watobo::Chats.sites(), YAML.load(YAML.dump(@project.scope)), prefs)
        @scannerSettingsFrame = ScannerSettingsFrame.new(base_frame, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        buttons_frame = FXHorizontalFrame.new(base_frame,
                                              :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        
        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
          #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end 
        
        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        
      end
    end
  end
end


if __FILE__ == $0
  # TODO Generated stub
end
