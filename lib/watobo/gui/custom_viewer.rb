# @private 
module Watobo#:nodoc: all
  module Gui
    
    class ViewerHandlerCtrl < FXHorizontalFrame
      attr :handler
      @@handler_path = nil
      
      def has_handler?
        !@handler.nil?
      end
      
      def initialize(parent, opts = { :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :padding => 0 })
        super parent, opts
        @parent = parent
        #handler_ctrl_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(self, "View Handler:")
        @handler_status_lbl = FXLabel.new(self, "None")
        @handler_status_lbl.backColor = "red"
        add_handler_btn = FXButton.new(self, "add", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        add_handler_btn.connect(SEL_COMMAND){ add_handler }
        reload_handler_btn = FXButton.new(self, "reload", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        reload_handler_btn.connect(SEL_COMMAND){ load_handler(@handler_file) }
        reset_handler_btn = FXButton.new(self, "reset", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        
        reset_handler_btn.connect(SEL_COMMAND){
          @handler = nil
          @handler_file = nil
          @handler_status_lbl.text =  "None"
          @handler_status_lbl.backColor = "red"
        }
      end
      
      
      def add_handler        
         handler_filename = FXFileDialog.getOpenFilename(self, "Select handler file", @@handler_path, "*.rb\n*")
          if handler_filename != "" then
            if File.exist?(handler_filename) then
              @handler_file = handler_filename
              @@handler_path = File.dirname(handler_filename) + "/"
              load_handler(handler_filename)
            end
          end
        
      end
      
      def load_handler(file)
        @handler = nil
        @handler_status_lbl.text = "None"
        @handler_status_lbl.backColor = "red"
        
        return false if file.nil?
        return false unless File.exist? file
        begin
          source = File.read(file)
          #puts source
          result = eval(source)
          if result.respond_to? :call
            @handler = result
            @handler_status_lbl.text = "#{File.basename(file).gsub(/\.rb$/,'')}"
            @handler_status_lbl.textColor = 'black'
            @handler_status_lbl.backColor = 'green'
            @parent.setText
          end
          return true
                     
         rescue SyntaxError, LocalJumpError, NameError => e
           out = e.to_s
           out << e.backtrace.join("\n")
         rescue => bang
           out = bang
           out << bang.backtrace.join("\n")
         end
         puts out
         return false
      end
      
      def call_handler(object)
        return object if @handler.nil?
        begin
          result = @handler.call(object)
          return result       
        rescue => bang
          result = bang.to_s
          result << bang.backtrace.join("\n")
          return result
        end
        
      end
    end

   
    class CustomViewer < FXVerticalFrame
      SEL_TYPE_GREP = 0
      SEL_TYPE_HIGHLIGHT = 1
      attr_accessor :max_len
      
      def style=(new_style)
        @simple_text_view.style = new_style
      end

      def editable=(value)
        @simple_text_view.editable = value
      end

      def setText(object=nil, prefs={})
        
        o = object.nil? ? @object : object
        return false if o.nil?
        @object = o
        normalized_text = o.to_s
        if o.is_a? Watobo::Request or o.is_a? Watobo::Response          
           if @handler_ctrl.has_handler?
             result = @handler_ctrl.call_handler(o)
             normalized_text =  result
           end
        else
          return false
        end
        
        @text = normalized_text
        #@text = text
        @simple_text_view.max_len = -1
        @simple_text_view.setText(normalized_text, prefs)
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'

        applyFilter() if @auto_apply_cbtn.checked?
      end

      def highlight(pattern)
        highlightPattern(pattern)
      end

      def setFont(font_type=nil, size=nil)
        @simple_text_view.setFont(font_type, size)
      end

      def getText
        @simple_text_view.textbox.to_s
      end

      def initialize(owner, opts)
        super(owner, opts)

        @text_matches = []

        @style = 2 # default style
        @text = ''
        @object = nil
        @max_len = 5000
        @filter_mode = SEL_TYPE_HIGHLIGHT
        @cur_match_pos = 0
        @text_dt = FXDataTarget.new('')
        @filter_dt = FXDataTarget.new('')
        
        @handler = nil
        @handler_file = nil
        @@handler_path = nil
        
        @handler_ctrl = ViewerHandlerCtrl.new(self)

        text_view_header = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_HEIGHT,:height => 24, :padding => 0)

        #@auto_apply_cbtn.connect(SEL_COMMAND, method(:onInterceptChanged))

        pmatch_btn = FXButton.new(text_view_header, "<", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y)
        @match_pos_label = FXLabel.new(text_view_header, "0/0", :opts => LAYOUT_FILL_Y)
        @match_pos_label.textColor = 'grey'
        pmatch_btn.connect(SEL_COMMAND) { gotoPrevMatch() }
        nmatch_btn = FXButton.new(text_view_header, ">", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y)
        nmatch_btn.connect(SEL_COMMAND) { gotoNextMatch() }

        #  @filter_text = FXTextField.new(text_view_header, 10,
        #  :target => @filter_dt, :selector => FXDataTarget::ID_VALUE,
        #  :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @filter_text = FXComboBox.new(text_view_header, 20, @filter_dt, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        @filter_text.connect(SEL_COMMAND){
          applyFilter()
          addFilterHistory()
        }

        @filter_text.connect(SEL_CHANGED) {
          applyFilter()
        }

        menu = FXMenuPane.new(self)
        FXMenuCommand.new(menu, "&Highlight").connect(SEL_COMMAND){
          @filter_mode = SEL_TYPE_HIGHLIGHT
          applyFilter()
          @mode_btn.text = "Highlight"
        }#, method(:switchMethod))
        FXMenuCommand.new(menu, "&Grep").connect(SEL_COMMAND){
          @filter_mode = SEL_TYPE_GREP
          applyFilter()
          @mode_btn.text = "Grep"
        }#, method(:switchMethod))

        @auto_apply_cbtn = FXCheckButton.new(text_view_header, "auto-apply", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_RIGHT|LAYOUT_FILL_Y)
        @mode_btn = FXMenuButton.new(text_view_header, "Highlight", nil, menu,
        :opts=> MENUBUTTON_DOWN|FRAME_RAISED|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_RIGHT|LAYOUT_FILL_Y)

        reset_button = FXButton.new(text_view_header, "&Reset", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y)
        reset_button.connect(SEL_COMMAND){ resetFilter() }

        text_box_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)

        @simple_text_view = SimpleTextView.new(text_box_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y,:padding => 0)
        @simple_text_view.style = 1
        @simple_text_view.editable = false
        @simple_text_view.textStyle -= TEXT_WORDWRAP

        addHotkeyHandler(@simple_text_view.textbox)
        addHotkeyHandler(@filter_text)

        @filter_dt.connect(SEL_COMMAND) { applyFilter() }

      end

      def applyFilter
        pattern = @filter_text.text
        @match_pos_label.text = "0/0"
        @simple_text_view.resetMatches()
        @simple_text_view.setText(@text)
        @match_pos_label.textColor = 'grey'
        return true if pattern == ''
        case @filter_mode
        when SEL_TYPE_GREP
          grepPattern(pattern)
        when SEL_TYPE_HIGHLIGHT
          highlightPattern(pattern)
        end
      end

      private

      def gotoNextMatch()
        @cur_match_pos += 1 if @cur_match_pos < @simple_text_view.numMatches-1
        @simple_text_view.makeMatchVisible(@cur_match_pos)
        @match_pos_label.text = "#{@cur_match_pos+1}/#{@simple_text_view.numMatches}" if @simple_text_view.numMatches > 0
      end

      def gotoPrevMatch()
        @cur_match_pos -= 1 if @cur_match_pos > 0
        @simple_text_view.makeMatchVisible(@cur_match_pos)
        @match_pos_label.text = "#{@cur_match_pos+1}/#{@simple_text_view.numMatches}" if @simple_text_view.numMatches > 0
      end

      def addFilterHistory()
        text = @filter_text.text
        return true if text == ''
        has_item = false
        @filter_text.each do |item, data|
          has_item = true if data == text
        end
        @filter_text.appendItem(text, text) unless has_item == true
        @filter_text.numVisible = @filter_text.numItems
      end

      def resetFilter
        @simple_text_view.max_len = 0
        @simple_text_view.setText(@text)
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'
        @filter_text.text = ''
      end

      def highlightPattern(pattern)
        @cur_match_pos = 0
        @simple_text_view.max_len = 0

        @match_pos_label.textColor = 'black'

        @simple_text_view.setText(@text)
        @simple_text_view.highlight(pattern)
        @match_pos_label.text = "0/#{@simple_text_view.numMatches()}"

        @simple_text_view.makeMatchVisible(0)

        @match_pos_label.text = "1/#{@simple_text_view.numMatches()}" if @simple_text_view.numMatches() > 0

      end

      def grepPattern(pattern)
        @cur_match_pos = 0
        @simple_text_view.max_len = 0

        @match_pos_label.textColor = 'black'

        @simple_text_view.setText(@text)

        @simple_text_view.filter(pattern)
        @match_pos_label.text = "0/#{@simple_text_view.numMatches()}"
        @simple_text_view.highlight(pattern)
        @simple_text_view.makeMatchVisible(0)

        @filter_mode = SEL_TYPE_GREP

        @match_pos_label.text = "1/#{@simple_text_view.numMatches()}" if @simple_text_view.numMatches() > 0

      end

      def addHotkeyHandler(widget)
        @ctrl_pressed = false

        widget.connect(SEL_KEYPRESS) { |sender, sel, event|
        # puts event.code
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_Return
            highlight(@filter_text.text)
          true # special handling of KEY_Return, because we don't want a linebreak in textbox.
          end

          if event.code == KEY_F1

            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "<ctrl-r> - Reset Filter",
                  "<ctrl-g> - Grep",
                  "<ctrl-h> - Highlight",
                  "<ctrl-n> - Goto Next",
                  "<ctrl-shift-n> - Goto Prev",
                  "<ctrl-w> - Switch Wordwrap"
                ].each do |hk|
                  FXMenuCaption.new(menu_pane, hk).backColor = 'yellow'
                end

                menu_pane.create
                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end
          end

          if @ctrl_pressed
            case event.code
            when KEY_n
              gotoNextMatch()
              addFilterHistory()
            when KEY_N
              gotoPrevMatch()
              addFilterHistory()
            when KEY_w
              @simple_text_view.textbox.textStyle ^= TEXT_WORDWRAP
            when KEY_h
              @mode_btn.text = "Highlight"
              @filter_mode = SEL_TYPE_HIGHLIGHT
              addFilterHistory()
              applyFilter()
            when KEY_g
              @mode_btn.text = "Grep"
              @filter_mode = SEL_TYPE_GREP
              addFilterHistory()
              applyFilter()
            when KEY_r
              resetFilter()

            end
          end
          false
        }

        widget.connect(SEL_KEYRELEASE) { |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        }
      end

    end
end
end