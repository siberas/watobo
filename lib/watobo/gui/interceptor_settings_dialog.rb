# @private 
module Watobo#:nodoc: all
  module Gui
    
    class InterceptorSettingsFrame < FXVerticalFrame
        
      
      def getSettings()
        settings = Hash.new
        settings[:port] = @port_dt.value
        settings[:bind_addr] = @bind_addr_dt.value
        mode = Watobo::Interceptor::MODE_REGULAR
        mode = Watobo::Interceptor::MODE_TRANSPARENT if @transparent_mode_chk.checked?
        settings[:proxy_mode] = mode
       
        
        
        dummy = []
        @ct_list.each do |nup|
          dummy.push nup.data
        end
        settings[:pass_through] = {
        :content_types => dummy,
        :content_length => @content_length_dt.value
        }
        
        return settings
      end
      
      def transparent_mode?
        @transparent_mode_chk.checked?
      end
      
      def addItem(list_box, item)   
        if item != "" then
          list_item = list_box.appendItem("#{item}")
          list_box.setItemData(list_item, item)
          list_box.sortItems()        
        end
      end
      
      def removePattern(list_box)
        index = list_box.currentItem
        if  index >= 0
          list_box.removeItem(index)
        end
      end
      
      def initialize(owner, opts)        
        super(owner, opts)
        
        #@settings = interceptor_settings
        scroller = FXScrollWindow.new(self, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_area = FXVerticalFrame.new(scroller, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
         gbox = FXGroupBox.new(scroll_area, "Transparent Mode", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
         gbox_frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_SIDE_TOP)
          @transparent_mode_chk = FXCheckButton.new(gbox_frame, "enable", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_LEFT)
          @transparent_mode_chk.setCheck false
          if RUBY_PLATFORM =~ /linux|bsd|solaris|hpux|darwin/i
            @transparent_mode_chk.setCheck true if Watobo::Conf::Interceptor.proxy_mode == Watobo::Interceptor::MODE_TRANSPARENT            
          else
            @transparent_mode_chk.disable
            note = FXLabel.new(gbox_frame, "Transparent Mode Only Available On Linux Platform!")
            note.textColor = FXColor::Red
            
          end
         
        gbox = FXGroupBox.new(scroll_area, "Listener", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        #gbox_frame = FXVerticalFrame.new(gbox, :opts => LAYOUT_SIDE_TOP|PACK_UNIFORM_WIDTH)
       frame = FXMatrix.new(gbox, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

      # frame = FXHorizontalFrame.new(gbox_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Bind Address:")
        @bind_addr_dt = FXDataTarget.new(0)
        #@port_dt.value = @settings[:port]
        @bind_addr_dt.value = Watobo::Conf::Interceptor.bind_addr
        bind_addr_txt = FXTextField.new(frame, 15, @bind_addr_dt, FXDataTarget::ID_VALUE, :opts => JUSTIFY_RIGHT|FRAME_GROOVE|FRAME_SUNKEN)
        bind_addr_txt .handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
       
       # frame = FXHorizontalFrame.new(gbox_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Port:")
        @port_dt = FXDataTarget.new(0)
        #@port_dt.value = @settings[:port]
        @port_dt.value = Watobo::Conf::Interceptor.port
        lport = FXTextField.new(frame, 5, @port_dt, FXDataTarget::ID_VALUE, :opts => JUSTIFY_RIGHT|FRAME_GROOVE|FRAME_SUNKEN)
        lport.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
       
        gbframe = FXGroupBox.new(scroll_area, "Pass-Through Content-Length", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Define Content-Length threshold for Pass-Through. Responses which Content-Length exceed this size will be forwarded."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(input_frame, "Max. Content-Length:")
        @content_length_dt = FXDataTarget.new('')
        #@content_length_dt.value = @settings[:pass_through][:content_length]
        @content_length_dt.value = Watobo::Conf::Interceptor.pass_through[:content_length]
        content_length_field = FXTextField.new(input_frame, 7, :target => @content_length_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
      content_length_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       
       
        
        gbframe = FXGroupBox.new(scroll_area, "Pass-Through Content-Types", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Define Content-Types for Pass-Through. Responses which are forwarded will not be inspected by Passive-Checks. So you only should define Content-Types which in general contain binary data."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @ct_dt = FXDataTarget.new('')
        @ct_field = FXTextField.new(input_frame, 20, :target => @ct_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_ct_btn = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @add_ct_btn = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @ct_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @ct_list.numVisible = 5
        
        @ct_list.connect(SEL_COMMAND){ |sender, sel, item|
          @ct_dt.value = sender.getItemText(item)
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
       # @settings[:pass_through][:content_types].each do |nup|
        Watobo::Conf::Interceptor.pass_through[:content_types].each do |nup|
          addItem(@ct_list, nup)
        end
        
        @rem_ct_btn.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@ct_list) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @add_ct_btn.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@ct_list, @ct_dt.value) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @ct_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addItem(@ct_list, @ct_dt.value) if @ct_dt.value != ''
          @ct_dt.value = ''
          @ct_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
      end
      
    end
    
    #
    # Class: SelectNonUniqueParmsDialog
    #
    class InterceptorSettingsDialog < FXDialogBox
      
      include Responder
      attr :interceptor_settings
      
      def transparent?
        @interceptorSettingsFrame.transparent_mode?
      end
      
      def onAccept(sender, sel, event)
        
        @interceptor_settings = @interceptorSettingsFrame.getSettings()
        
        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end
      
      
      def initialize(owner)
        super(owner, "Interceptor Settings", DECOR_TITLE|DECOR_BORDER, :width => 400, :height => 500)
        #@interceptor_settings = interceptor_settings
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        
        
        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        #  puts "create scopeframe with scope:"
        # @project.scope
        # @defineScopeFrame = DefineScopeFrame.new(base_frame, Watobo::Chats.sites(), YAML.load(YAML.dump(@project.scope)), prefs)
        @interceptorSettingsFrame = InterceptorSettingsFrame.new(base_frame, :opts => SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
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
