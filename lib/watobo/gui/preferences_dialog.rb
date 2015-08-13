# @private 
module Watobo#:nodoc: all
  module Gui
    class PreferencesDialog_UNUSED < FXDialogBox
      
      attr :settings
      
      include Responder
      
      
        def onAccept(sender, sel, event)
          @settings[:enable_smart_scan] = @enable_smart_scan.checked?
          @settings[:max_parallel_checks] = @max_par_checks_dt.value
          @settings[:intercept_port] = @intercept_port_dt.value

          getApp().stopModal(self, 1)
          self.hide()
          return 1

      end
      
      def startProxyDialog(sender, sel, ptr)
         proxy_dialog = Watobo::Gui::ProxyDialog.new(self, @settings[:proxy], @settings[:proxy_list])
        if proxy_dialog.execute != 0 then
          @settings[:proxy_list] = proxy_dialog.getProxyList
          @settings[:proxy] = proxy_dialog.proxy
          @forwarding_proxy_dt.value = @settings[:proxy]
          @forwarding_proxy.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end
      end
      
      def initialize(owner, settings)
        super(owner, "Preferences", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE)
        
         FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
         
        @settings = Hash.new
        @settings.update(settings)
        
        @advancedFrame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        gbox_frame = FXGroupBox.new(@advancedFrame, "Scan Options ", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        gbox = FXVerticalFrame.new(gbox_frame, :opts => LAYOUT_SIDE_TOP|PACK_UNIFORM_WIDTH)
        frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
        FXLabel.new(frame, "Max. Par. Request:")
        @max_par_checks_dt = FXDataTarget.new(0)
        @max_par_checks_dt.value = @settings[:max_parallel_checks]
        @max_par_checks = FXTextField.new(frame, 3, @max_par_checks_dt, FXDataTarget::ID_VALUE, :opts => JUSTIFY_RIGHT|FRAME_GROOVE|FRAME_SUNKEN)
        
        
        @enable_smart_scan = FXCheckButton.new(gbox, "Enable Smart Scan ", nil, 0, JUSTIFY_RIGHT|JUSTIFY_TOP|ICON_AFTER_TEXT|LAYOUT_SIDE_RIGHT)
        @enable_smart_scan.checkState = @settings[:smart_scan]
        
       #-------------------------- Forwarding Proxy ---------------------------------#
      #  gbox = FXGroupBox.new(@advancedFrame, "Forwarding Proxy",LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
      #  frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
      #  FXLabel.new(frame, "Current: ")
      #  @forwarding_proxy_dt = FXDataTarget.new('')
      #  @forwarding_proxy = FXTextField.new(frame, 20, @forwarding_proxy_dt, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
        
      #  @forwarding_proxy_dt.value = @settings[:proxy]
      #  button = FXButton.new(frame, "View/Edit" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
      #  button.enable
      #  button.connect(SEL_COMMAND, method(:startProxyDialog))
       
        #-------------------------- Interceptor ---------------------------------#
      #  gbox = FXGroupBox.new(@advancedFrame, "Interceptor",LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
      #  frame = FXHorizontalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_RIGHT)
      #  FXLabel.new(frame, "Listener Port: ")
      #  @intercept_port_dt = FXDataTarget.new(@settings[:intercept_port])
      #  @intercept_port = FXTextField.new(frame, 0, @intercept_port_dt, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
       
        
        buttons_frame = FXHorizontalFrame.new(@advancedFrame, :opts => LAYOUT_FILL_X)
        
          @cancelButton = FXButton.new(buttons_frame, "Accept" ,
        :target => self, :selector => FXDialogBox::ID_ACCEPT,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        
        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        @max_par_checks.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       # @forwarding_proxy.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       # @intercept_port.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
        
      end
    end
  end
end

if __FILE__ == $0
  # TODO Generated stub
end
