# @private 
module Watobo#:nodoc: all
  module Gui
    
   # class ConversationFilterFrame < FXVerticalFrame
   class ConversationFilterDialog < FXDialogBox
     
     include Responder
     
     
      def filter_settings
        fs = {
          :scope_only => @table_option_scope.checked?,         
          :hide_tested => @table_option_hidetested_cb.checked?,
          :unique => @table_option_unique.checked?
        }
        
        pattern = @text_filter.text
        unless pattern.empty?
          begin
            "test for valid regex".match(/#{pattern}/)
          rescue => bang
            pattern = Regexp.quote(@text_filter.text)
          end
        
        
        end
        fs[:url_pattern] = @foption_url.checked? ? pattern : ''
        fs[:request_pattern] = @foption_req.checked? ? pattern : ''
        fs[:response_pattern] = @foption_res.checked? ? pattern : ''
        
        mime_types = []
        mime_types << "html" if @mime_html.checked?
        mime_types << "css" if @mime_css.checked?
        mime_types << "flash" if @mime_flash.checked?
        mime_types << "script" if @mime_script.checked?
        mime_types << "xml" if @mime_xml.checked?  
        fs[:mime_types] = mime_types
        
        status_codes = []
        status_codes << "^2" if @status_2.checked?      
        status_codes << "^3" if @status_3.checked?
        status_codes << "^4" if @status_4.checked?
        status_codes << "^5" if @status_5.checked?
        fs[:status_codes] = status_codes
        
        hidden_extension_patterns = []
        hidden_extension_patterns.concat @hide_ex.text.split(",").map{|e| e.strip } 
      #  hidden_extension_patterns.concat @hide_images_ex.text.split(",").map{|e| e.strip } if @hide_images.checked?
        fs[:hidden_extension_patterns] = hidden_extension_patterns
        fs[:hidden_extensions] = @hide_ex_cb.checked?
        
        show_extension_patterns = []
        show_extension_patterns.concat @show_only_ex.text.split(",").map{|e| e.strip } 
        fs[:show_extensions] = @show_extensions_cb.checked?
        fs[:show_extension_patterns] = show_extension_patterns
              
          
        fs
      end
      
      
      def initialize(owner, filter)
        super(owner, "Filter Settings", :opts => DECOR_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED )
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        matrix = FXMatrix.new(main, 5, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        f = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        generell_gb = FXGroupBox.new(f, "Generell", FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        generell_frame = FXVerticalFrame.new(generell_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @table_option_unique = FXCheckButton.new(generell_frame, "unique chats", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:unique) ? filter[:unique] : false
        @table_option_unique.setCheck(state)

        @table_option_scope = FXCheckButton.new(generell_frame, "scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
       
        state = filter.has_key?(:scope_only) ? filter[:scope_only] : false
        @table_option_scope.setCheck(state)

        @table_option_hidetested_cb = FXCheckButton.new(generell_frame, "hide tested", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:hide_tested) ? filter[:hide_tested] : false
        @table_option_hidetested_cb.setCheck(state)        
        
        f = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        mime_types_gb = FXGroupBox.new(f, "MIME Types", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        mime_types_frame = FXVerticalFrame.new(mime_types_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        
        
        @mime_html = FXCheckButton.new(mime_types_frame, "HTML", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:mime_types) ? filter[:mime_types].include?("html") : false 
        @mime_html.setCheck(state)
        
        @mime_css = FXCheckButton.new(mime_types_frame, "CSS", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:mime_types) ? filter[:mime_types].include?("css") : false
        @mime_css.setCheck(state)
        
        @mime_xml = FXCheckButton.new(mime_types_frame, "XML", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:mime_types) ? filter[:mime_types].include?("xml") : false
        @mime_xml.setCheck(state)
        
        @mime_script = FXCheckButton.new(mime_types_frame, "Script", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:mime_types) ? filter[:mime_types].include?("script") : false
        @mime_script.setCheck(state)
        
        @mime_flash = FXCheckButton.new(mime_types_frame, "Flash", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:mime_types) ? filter[:mime_types].include?("flash") : false
        @mime_flash.setCheck(state)
        
        f = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        status_codes_gb = FXGroupBox.new(f, "Status Codes", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        status_codes_frame = FXVerticalFrame.new(status_codes_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @status_2 = FXCheckButton.new(status_codes_frame, "2xx", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:status_codes) ? filter[:status_codes].include?("^2") : false
        @status_2.setCheck(state)
        
        @status_3 = FXCheckButton.new(status_codes_frame, "3xx", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:status_codes) ? filter[:status_codes].include?("^3") : false
        @status_3.setCheck(state)
        @status_4 = FXCheckButton.new(status_codes_frame, "4xx", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:status_codes) ? filter[:status_codes].include?("^4") : false
        @status_4.setCheck(state)
        @status_5 = FXCheckButton.new(status_codes_frame, "5xx", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:status_codes) ? filter[:status_codes].include?("^5") : false
        @status_5.setCheck(state)
        
        
        f = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        extension_gb = FXGroupBox.new(f, "Extensions", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        extension_frame = FXVerticalFrame.new(extension_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        extension_matrix = FXMatrix.new(extension_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @show_extensions_cb = FXCheckButton.new(extension_matrix, "Show only: ", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:show_extensions) ? filter[:show_extensions] : false
        @show_extensions_cb.setCheck(state)  
        @show_only_ex = FXTextField.new(extension_matrix, 25, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)        
        @show_only_ex.text = filter.has_key?(:show_extension_patterns) ? filter[:show_extension_patterns].join(", ") : "jsp, php, asp, aspx"
        
        @hide_ex_cb = FXCheckButton.new(extension_matrix, "Hide: ", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = filter.has_key?(:hidden_extensions) ? filter[:hidden_extensions] : false
       # @show_extensions_cb.setCheck(state)  
        @hide_ex_cb.setCheck(state)
        f = FXVerticalFrame.new(extension_matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_SUNKEN, :padding => 0)  
        @hide_ex =  FXText.new(f, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        @hide_ex.text = filter.has_key?(:hidden_extension_patterns) ? filter[:hidden_extension_patterns].join(", ") : "ppt, doc, xls, pptx, docx, xlsx, pdf, jpg, jpeg, ico, png, css, gif, js"
          
        # PATTERN
        f = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        pattern_gb = FXGroupBox.new(f, "Pattern", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        pattern_frame = FXVerticalFrame.new(pattern_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
      
        
        @text_filter = FXTextField.new(pattern_frame, 40, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)
        @text_filter.setFocus()
        @text_filter.setDefault()
       
        @text_filter.connect(SEL_COMMAND){
           @accept_btn.setFocus()
           @accept_btn.setDefault()
        #  self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
          true
        }
        
        [ :url_pattern, :request_pattern, :response_pattern ].each do |k|
          if filter.has_key? k
            @text_filter.text = filter[k] unless filter[k].empty?
          end
        end
        # filterOptionsFrame =FXHorizontalFrame.new(fbox, LAYOUT_FILL_X)
        @foption_url = FXCheckButton.new(pattern_frame, "&URL", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = ( filter.has_key?(:url_pattern) and not filter[:url_pattern].empty? )
        @foption_url.setCheck(state)
       # @foption_url.connect(SEL_COMMAND){ update_text_filter }
        @foption_req = FXCheckButton.new(pattern_frame, "Re&quest", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = ( filter.has_key?(:request_pattern) and not filter[:request_pattern].empty? )
        @foption_req.setCheck state
       # @foption_req .connect(SEL_COMMAND){ update_text_filter }
        @foption_res = FXCheckButton.new(pattern_frame, "Res&ponse", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        state = ( filter.has_key?(:response_pattern) and not filter[:response_pattern].empty? )
        @foption_res.setCheck state
       # @foption_res.connect(SEL_COMMAND){ update_text_filter }
         
       buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          @accept_btn = FXButton.new(buttons, "&Apply", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        @accept_btn.enable
        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        
      end
      
      private
      
      def onAccept(sender, sel, item)
        getApp().stopModal(self, 1)
        self.hide()
        return 1
        
      end
    end
    
    
    
    
    class ConversationTableCtrl2 < FXVerticalFrame

      include Watobo::Constants
      include Watobo::Gui::Icons
      
      attr :filter
      
      def table=(table)
        @table = table
       # @table.subscribe(:table_changed) { update_info }
      end
      
      def update_text
       @filter_info.text = filter_text
       @filter_info.appendText "     "
       @filter_info.appendStyledText("click to change", 1)
       
     end
     
     def text=(t)
       @filter_info.text = t
       @filter_info.appendText "     "
       @filter_info.appendStyledText("click to change", 1)
     end
      
      def default_filter
        fs = {
          :scope_only => false  ,       
          :hide_tested => false,
          :unique => false
        }
        
        fs[:url_pattern] = ''
        fs[:request_pattern] = ''
        fs[:response_pattern] = ''
        fs[:mime_types] = []
        fs[:status_codes] = []
        fs[:hidden_extension_patterns] = %w( ppt doc xls pptx docx xlsx pdf jpg jpeg ico png css gif js)
        fs[:hidden_extensions] = true
        fs[:show_extensions] = false
        fs[:show_extension_patterns] = %w(jsp php asp aspx)
        fs
        
      end

      def initialize(owner, opts)
        super(owner, opts)
        @table = nil
        @filter = default_filter
        
        f = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|FRAME_RAISED )
        
        info_frame = FXHorizontalFrame.new(f, :opts => LAYOUT_FILL_X|FRAME_LINE )
      #  @filter_info = FXButton.new(f,"Filter: ", :opts => LAYOUT_FILL_X|FRAME_LINE|FRAME_NORMAL|JUSTIFY_LEFT)
        @filter_info = FXText.new(info_frame, :opts => LAYOUT_FILL_X|TEXT_WORDWRAP )
        @filter_info.setFont(FXFont.new(getApp(), "helvetica", 9, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))
        @filter_info.backColor = @filter_info.parent.backColor
        @filter_info.editable = false
        @filter_info.cursorColor = @filter_info.parent.backColor
        @filter_info.visibleRows = 2
         hs_green = FXHiliteStyle.new
        hs_green.normalForeColor = FXRGBA(0,255,0,1) 
        hs_green.normalBackColor = @filter_info.backColor
        hs_green.style = FXText::STYLE_BOLD

        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,0,0,1)   
        hs_red.normalBackColor = @filter_info.backColor
        hs_red.style = FXText::STYLE_BOLD

        # Enable the style buffer for this text widget
        @filter_info.styled = true
        # Set the styles
        @filter_info.hiliteStyles = [ hs_green, hs_red]
        
       # @filter_info.setText(filter_text)
       update_text
       # l = FXLabel.new(@filter_info, "Test")
       
       bframe = FXVerticalFrame.new(f, :opts => LAYOUT_FILL_Y, :padding => 0)
        @table_option_autoscroll = FXCheckButton.new(bframe, "autoscroll", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_autoscroll.setCheck(true)
        
        @table_option_autoscroll.connect(SEL_COMMAND){
          puts "* Autoscroll >> #{@table_option_autoscroll.checked?.class}"
          @table.autoscroll = @table_option_autoscroll.checked?
        }
        
        iframe = FXHorizontalFrame.new(bframe, :opts => LAYOUT_FILL_X, :padding => 0 )
        
        FXButton.new(iframe, "", ICON_BTN_DOWN, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT).connect(SEL_COMMAND) {
          @table.scrollDown() unless @table.nil?
        }
        
        FXButton.new(iframe, "", ICON_BTN_UP, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT).connect(SEL_COMMAND) {
          @table.scrollUp() unless @table.nil?
        }

        
        
         

        
        
        
        
        @filter_info.connect(SEL_LEFTBUTTONPRESS){
          filter = @table.nil? ? {} : @table.filter
         dlg = Watobo::Gui::ConversationFilterDialog.new(self, filter)
          if dlg.execute != 0
            #puts dlg.filter_settings.to_yaml
            @filter = dlg.filter_settings
            
            unless @table.nil?
              getApp().beginWaitCursor do
                @table.apply_filter(@filter)           
              end
            end
            update_text         
          end
        }
=begin        
        @filter_info.connect(SEL_COMMAND){
           @x = getApp.activeWindow.x + self.x + self.parent.x + self.parent.parent.x + self.parent.parent.parent.x + self.parent.parent.parent.parent.x
         @y = getApp.activeWindow.y + self.y + self.parent.y + self.parent.parent.y + self.parent.parent.parent.y + self.parent.parent.parent.parent.y
         @w = 200
          puts "open menu | #{@x}, #{@y}"
           FXMenuPane.new(self) do |menu_pane|
             #frame = ConversationFilterFrame.new(menu_pane, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => @w, :height => 200)
             frame = ConversationFilterFrame.new(menu_pane, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X)
             
             
             menu_pane.create
             #menu_pane.popup(nil, x, y, 200, 200)
             menu_pane.popup(nil, @x, @y)
             app.runModalWhileShown(menu_pane)
             puts "done!"
             puts frame.filter_settings.to_yaml
          end
        }
=end        
        
      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

     
      private
      
      def filter_text
        text = ""
        text = "Show: "
        show_only = [] 
        show_only << "scope only" if @filter[:scope_only] == true
        show_only << "specific extensions" if @filter[:show_extensions] == true
        show_only << "URL pattern" unless @filter[:url_pattern].empty?
        show_only << "request pattern" unless @filter[:request_pattern].empty?
        show_only << "response pattern" unless @filter[:response_pattern].empty?
        show_only << "specific status codes" unless @filter[:status_codes].empty?
        show_only << "specific mime types" unless @filter[:mime_types].empty?
        text << show_only.join(", ")
        text << "All" if show_only.empty?
        
        
        text << " / Hide:"
        hide = []
        hide << "specific extensions" if @filter[:hidden_extensions] == true
        hide << "tested chats" if @filter[:hide_tested] == true
        text << hide.join(", ")
        text << "None" if hide.empty?
        
        unless @table.nil?
          text << "\n#{@table.numRows}/#{Watobo::Chats.length}"
        end
        text
      end

     
      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def clear_text_filter
        @text_filter.text = ''
        apply_filter
      end

      def apply_filter
        unless @table.nil?
          getApp().beginWaitCursor do
            @table.apply_filter(filter_settings)
           # update_info
          end
        end
      end

      def update_text_filter
        if @foption_url.checked? or @foption_req.checked? or @foption_res.checked?
        @text_filter.enable
        else
        @text_filter.disable
        end
      end

      

    end
  end
end