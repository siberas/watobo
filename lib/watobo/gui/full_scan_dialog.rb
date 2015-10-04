# @private 
module Watobo#:nodoc: all
  module Gui
    
    class FullScanDialog < FXDialogBox
      
      include Responder
      attr :active_policy
      attr :scope
      attr :prefs
      attr :activeModules
      attr :scan_prefs
      
      def onAccept(sender, sel, event)
        
        @scope = @defineScopeFrame.getScope() 
        @activeModules = @policyFrame.getSelectedModules()
        
        @scan_prefs = @scannerOptions.getSettings()
        
        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end
      
      def setButtons(index)
        case index
          when 0 
          @nextButton.enable
          @backButton.disable
          @finishButton.disable
          
          when 1
          # select session screen
          @nextButton.enable
          @backButton.enable
          @finishButton.enable
          
          when 2
          # select session screen
          @nextButton.disable
          @backButton.enable
          @finishButton.enable
          
          when 3
            puts "3"
          @nextButton.disable
          @backButton.enable
          @finishButton.enable
          
          
        end
      end
      
      
      
      def initialize(owner, project, prefs)
        super(owner, "Start Full Scan", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        @project = project
        @scope = Hash.new
        
        @scan_prefs = nil
        
        @selectedProxy = @project.settings[:proxy]
        @selectedProxyList = @project.settings[:proxy_list]
        
        @login_chat_ids = @project.getLoginChatIds  
        @sid_patterns = @project.getSidPatterns
        @logout_signatures = @project.getLogoutSignatures
        
        
        
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        
        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        @switcher = FXSwitcher.new(base_frame,LAYOUT_FILL_X|LAYOUT_FILL_Y)   
        
        @defineScopeFrame = DefineScopeFrame.new(@switcher, prefs)
        
        @policyBase = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        smf = FXHorizontalFrame.new(@policyBase, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP|FRAME_GROOVE)
        FXLabel.new(smf, "Select Checks")
        
        @policyFrame = ChecksPolicyFrame.new(@policyBase, @project.getScanPolicy)
        
      #  @scannerOptions = ScannerSettingsFrame.new(@switcher, @project.getScanPreferences(),:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @scannerOptions = ScannerSettingsFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        #   @advancedFrame = AdvancedSettingsFrame.new(@switcher, @project, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        
        
        buttons_frame = FXHorizontalFrame.new(base_frame,
                                              :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        
        @finishButton = FXButton.new(buttons_frame, "Start" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @finishButton.disable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
          #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end 
        
        @nextButton = FXButton.new(buttons_frame, "Next" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @nextButton.enable
        @nextButton.connect(SEL_COMMAND) do |sender, sel, item|
          if @switcher.current < @switcher.numChildren-1
            @switcher.current = @switcher.current+1
            
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
        
        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        
      end
    end
    
    class AdvancedSettingsFrame < FXVerticalFrame
      
      def startProxyDialog(sender, sel, ptr)
        proxy_dialog = Watobo::Gui::ProxyDialog.new(self, @selectedProxy, @selectedProxyList)
        if proxy_dialog.execute != 0 then
          @selectedProxyList = proxy_dialog.getProxyList
          @selectedProxy = proxy_dialog.proxy
          @forwardingProxy.value = @selectedProxy
        end
      end
      
      def startSessionManagementDialog(sender, sel, ptr)
        smdlg = SessionManagementDialog.new(self, @project)
        if smdlg.execute != 0 then
          
          @login_chat_ids = smdlg.getLoginScriptIds() 
          @sid_patterns = smdlg.getSidPatterns()
          @logout_signatures = smdlg.getLogoutSignatures()
          
        end
      end
      
      
      def initialize(owner, project, opts)
        super(owner, opts)
        @project = project
        smf = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        FXLabel.new(smf, "Advanced Settings")
        
        gbox = FXGroupBox.new(self, "Excluded Chats",LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        @excludedChats = FXDataTarget.new('')
        @excludedChats.value = @project.scan_settings[:excluded_chats].join(", ")
        FXTextField.new(gbox, 0, @excludedChats, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
        
        frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
        button = FXButton.new(frame, "View/Edit" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        button.enable
        button.connect(SEL_COMMAND) do |sender, sel, item|
          
        end
        @ignoreEqualChats = FXCheckButton.new(frame, "Ignore Similar Chats", nil, 0, ICON_AFTER_TEXT|LAYOUT_LEFT)
        @ignoreEqualChats.checkState = false
        #-------------------------- Proxy ---------------------------------#
        gbox = FXGroupBox.new(self, "Forwarding Proxy",LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
        FXLabel.new(frame, "Current: ")
        @forwardingProxy = FXDataTarget.new('')
        FXTextField.new(frame, 0, @forwardingProxy, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
        
        @forwardingProxy.value = @project.settings[:proxy]
        button = FXButton.new(frame, "View/Edit" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        button.enable
        button.connect(SEL_COMMAND, method(:startProxyDialog))
        #-------------------------- Session Management ---------------------------------#
        gbox = FXGroupBox.new(self, "Session Management",LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
        #FXLabel.new(frame, " ")
        button = FXButton.new(frame, "View/Edit" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        button.enable
        button.connect(SEL_COMMAND, method(:startSessionManagementDialog))
        
      end
    end
  end
end


if __FILE__ == $0
  
  require '../utils/check_regex'
  require '../project'
  
  
  
  class TestGui < FXMainWindow
    class DummyProject < Watobo::Project
      def initialize()
        super(nil,Hash.new)
      end
      def listSites
        return ["127.0.0.1"]
      end
    end
    
    def startDialog
      project = DummyProject.new()
      
      dlg = Watobo::Gui::FullScanDialog.new(self,project,DECOR_TITLE|DECOR_BORDER)
      
      if dlg.execute != 0
        puts dlg.details.to_yaml
      end
    end
    
    def initialize(app)
      # Call base class initializer first
      super(app, "Test Application", :width => 800, :height => 600)
      frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
      
      pbButton = FXButton.new(frame, "create FXProgressBar",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,:padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
      
      # @project = 
      pbButton.connect(SEL_COMMAND) { startDialog() }
    end
    # Create and show the main window
    def create
      super                  # Create the windows
      show(PLACEMENT_SCREEN) # Make the main window appear
      
      startDialog()  
    end
  end
  application = FXApp.new('LayoutTester', 'FoxTest')  
  TestGui.new(application)
  application.create
  application.run
end
