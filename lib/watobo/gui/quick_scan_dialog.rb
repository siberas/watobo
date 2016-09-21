# @private 
module Watobo#:nodoc: all
  module Gui
    class QuickScanOptionsFrame < FXVerticalFrame
      def options()
        csrf_requests = Watobo::OTTCache.requests(@target_chat)
        
        o = Hash.new
        o[:enable_logging] = @logScanChats.checked?
        o[:scanlog_name] = @scanlog_name_dt.value
        o[:csrf_tokens] = @csrf_patterns
        o[:csrf_request_ids] = @csrf_ids
        o[:csrf_requests] = csrf_requests
        o[:update_csrf_tokens] = @csrfToken.checked?
        o[:use_orig_request] = @useOriginalRequest.checked?
        o[:detect_logout] = @detectLogout.checked?
        o[:follow_redirect] = @followRedirects.checked?
        puts o.to_yaml if $DEBUG
        o
      end

      def initialize(owner, prefs = {} )

        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @csrf_ids = []
        @csrf_patterns = []
        @target_chat = prefs[:target_chat]

        # scan_opt_frame= FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @useOriginalRequest = FXCheckButton.new(self, "Use original request", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @useOriginalRequest.checkState = true
        
        @followRedirects = FXCheckButton.new(self, "Follow redirects", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @followRedirects.checkState = false
        
        @detectLogout = FXCheckButton.new(self, "Autom. login when logged out", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @detectLogout.checkState = false

        frame = FXGroupBox.new(self, "Logging", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        @logScanChats = FXCheckButton.new(frame, "Log Scan", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @logScanChats.checkState = false
        @logScanChats.connect(SEL_COMMAND) do |sender, sel, item|
          if @logScanChats.checked? then
            @scanlog_name_text.enabled = true
            @scanlog_dir_label.enabled = true
          #  @scanlog_dir_btn.enable
          else
            @scanlog_name_text.enabled = false
            @scanlog_dir_label.enabled = false
           # @scanlog_dir_btn.disable
          end
        end

        @scanlog_name_dt = FXDataTarget.new('')
       # @scanlog_name_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())
        @scanlog_dir_label = FXLabel.new(frame, "Scan-Name:" )
        scanlog_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        @scanlog_name_text = FXTextField.new(scanlog_frame, 20,
        :target => @scanlog_name_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
        @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       # @scanlog_dir_btn = FXButton.new(scanlog_frame, "Change")
       # @scanlog_dir_btn.connect(SEL_COMMAND, method(:selectScanlogDirectory))

        @scanlog_name_text.enabled = false
        @scanlog_dir_label.enabled = false
      #  @scanlog_dir_btn.disable

        frame = FXGroupBox.new(self, "One-Time-Token Settings", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        csrf_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP, :padding => 0)
        @csrfToken = FXCheckButton.new(csrf_frame, "Update One-Time-Tokens", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@csrfToken.checkState = false
        @csrfToken.checkState = prefs.has_key?(:enable_one_time_tokens) ? prefs[:enable_one_time_tokens] : false

        @csrfToken.connect(SEL_COMMAND) do |sender, sel, item|
          if @csrfToken.checked? then
            @csrf_dialog_btn.enable
          else
            @csrf_dialog_btn.disable
          end
        end

        @csrf_dialog_btn = FXButton.new(csrf_frame, "O-T-T Settings")
        @csrf_dialog_btn.connect(SEL_COMMAND, method(:openCSRFTokenDialog))

        #  @csrf_dialog_text.enabled = false
        #  @csrf_dialog_label.enabled = false
        @csrf_dialog_btn.disable
        @csrf_dialog_btn.enable if @csrfToken.checked?
      end

      private

      def openCSRFTokenDialog(sender, sel, item)
        csrf_dlg = CSRFTokenDialog.new(self, @target_chat)
        if csrf_dlg.execute != 0 then
          @csrf_ids = csrf_dlg.getTokenScriptIds()
          @csrf_patterns = csrf_dlg.getTokenPatterns()

          Watobo.project.setCSRFRequest(@target_chat.request, @csrf_ids, @csrf_patterns)

        end
      end

      def selectScanlogDirectory(sender, sel, item)
        workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Scanlog Directory", @scanlog_name_dt.value)
        if workspace_dt != "" then
          if File.exist?(workspace_dt) then
            @scanlog_name_dt.value = workspace_dt
            @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end
        end
      end

    end

    class QuickScanDialog < FXDialogBox

      include Responder

      attr :active_policy
      attr :selectedModules
      attr :options
      
      def initialize(parent, prefs={} )
        super(parent, "Quick Scan", DECOR_ALL, :width => 300, :height => 400)
        # @active_policy = 'Default'
        @selectedModules = []
        
        
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @switcher = FXSwitcher.new(base_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)

         @quickScanOptionsFrame = QuickScanOptionsFrame.new(@switcher, prefs)
        #@quickScanOptionsFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

      #  @policyFrame = ChecksPolicyFrame.new(@switcher, project.active_checks, project.settings[:policy])
        @policyFrame = ChecksPolicyFrame.new(@switcher)
       #@policyFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        # BUTTONS
        buttons_frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X)
        @startButton = FXButton.new(buttons_frame, "Start" ,
        :target => self, :selector => FXDialogBox::ID_ACCEPT,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @startButton.disable

        @nextButton = FXButton.new(buttons_frame, "Next" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @nextButton.enable
        @nextButton.connect(SEL_COMMAND) do |sender, sel, item|
          if @switcher.current < @switcher.numChildren - 1
            @switcher.current = @switcher.current + 1

          end
          setButtons(@switcher.current)
        end

        @backButton = FXButton.new(buttons_frame, "Back" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @backButton.disable
        @backButton.connect(SEL_COMMAND) do |sender, sel, item|
          if @switcher.current > 0
            @switcher.current = @switcher.current-1

          end
          setButtons(@switcher.current)
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" , :target => self, :selector => FXDialogBox::ID_CANCEL, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

        #@filterCombo.appendItem("ohne Filter", nil)

      end

      private

      def onAccept(sender, sel, event)
      #  @selectedPolicy = @policyFrame.policy_name
        @options = @quickScanOptionsFrame.options
        @selectedModules = @policyFrame.getSelectedModules()
        getApp().stopModal(self, 1)
        self.hide()
        1
      end

      def setButtons(index)
        case index
        when 0

          @nextButton.enable
          @backButton.disable
          @startButton.disable

        when 1
          # select session screen
          @nextButton.disable
          @backButton.enable
          @startButton.enable
        end
      end

    end
  end
end
