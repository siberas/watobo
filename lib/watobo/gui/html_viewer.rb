require 'fox16/scintilla'

# @private 
module Watobo#:nodoc: all
  module Gui
    class HTMLViewer < FXScintilla
      attr_accessor :max_len
      
      def search_text(text, &block)
        matches = []
        setTargetStart 0
        setTargetEnd getLength
        while searchInTarget(text.length, text) >= 0
         pos = getTargetStart
         setTargetStart pos+1
        setTargetEnd getLength
        yield pos if block_given?
        matches << pos
         end
         
         matches
      end      
      
      
      def initialize(owner, opts)
        super(owner, nil, 0, opts)
        self.setLexer FXScintilla::SCLEX_HTML
        self.setCodePage(FXScintilla::SC_CP_UTF8)
        self.styleSetFont(FXScintilla::STYLE_DEFAULT, "fixed")
        self.styleSetSize(FXScintilla::STYLE_DEFAULT, 9)
        self.styleClearAll
        self.styleSetFore(FXScintilla::SCE_P_DEFAULT, FXRGB(0x80, 0x80, 0x80) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_COMMENTLINE, FXRGB(0x00, 0x7f, 0x00) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_NUMBER, FXRGB(0x00, 0x7f, 0x7f) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_STRING, FXRGB(0x7f, 0x00, 0x7f) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_CHARACTER, FXRGB(0x7f, 0x00, 0x7f) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_WORD, FXRGB(0x00, 0x00, 0x7f) & 0xffffff)
        self.styleSetBold(FXScintilla::SCE_P_WORD, true)
        self.styleSetFore(FXScintilla::SCE_P_TRIPLE, FXRGB(0x7f, 0x00, 0x00) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_TRIPLEDOUBLE, FXRGB(0x7f, 0x00, 0x00) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_CLASSNAME, FXRGB(0x00, 0x00, 0xff) & 0xffffff)
        self.styleSetBold(FXScintilla::SCE_P_CLASSNAME, true)
        self.styleSetFore(FXScintilla::SCE_P_DEFNAME, FXRGB(0x00, 0x7f, 0x7f) & 0xffffff)
        self.styleSetBold(FXScintilla::SCE_P_DEFNAME, true)
        self.styleSetBold(FXScintilla::SCE_P_OPERATOR, true)
        self.styleSetFore(FXScintilla::SCE_P_IDENTIFIER, FXRGB(0x7f, 0x7f, 0x7f) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_COMMENTBLOCK, FXRGB(0x7f, 0x7f, 0x7f) & 0xffffff)
        self.styleSetFore(FXScintilla::SCE_P_STRINGEOL, FXRGB(0x00, 0x00, 0x00) & 0xffffff)
        self.styleSetBack(FXScintilla::SCE_P_STRINGEOL, FXRGB(0xe0, 0xc0, 0xe0) & 0xffffff)
        self.styleSetEOLFilled(FXScintilla::SCE_P_STRINGEOL, true)
        self.styleSetFore(34, FXRGB(0x00, 0x00, 0xff) & 0xffffff)
        self.styleSetBold(34, true)
        self.styleSetFore(35, FXRGB(0xff, 0x00, 0x00) & 0xffffff)
        self.styleSetBold(35, true)
        @max_len = 0
      end
    end
    
     class HTMLViewerFrame < FXVerticalFrame

      attr_accessor :max_len

      def setText(text, prefs={})
       
        normalized_text = "- empty -"
        if text.is_a? String
           normalized_text = text.gsub(/[^[:print:]]/,".")
        elsif text.respond_to? :has_body?
          unless text.body.nil? or text.body.empty?
            body = text.body.strip      
            if text.content_type =~ /(html|xml)/
              doc = Nokogiri::XML(body, &:noblanks)
              fbody = doc.to_xhtml( indent:3, indent_text:" ")
              normalized_text = fbody.to_s          
            else
              normalized_text = body
            end
          end
        elsif text.is_a? Array        
          normalized_text = text.join         
        end
        
         @text = normalized_text
       
       # puts normalized_text
        @html_viewer.setText(@text)
       #@html_viewer.encodedFromUTF8(normalized_text)
        
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'
        
         @html_viewer.setTargetStart 0
         @html_viewer.setTargetEnd @html_viewer.getLength

        applyFilter() if @auto_apply_cbtn.checked?
      end

      def highlight(pattern)
        highlightPattern(pattern)
      end

      def getText
        @html_viewer.to_s
      end

      def initialize(owner, opts)
        super(owner, opts)

        @text_matches = []

        @style = 2 # default style
        @text = ''
        @max_len = 5000
        @filter_mode = SEL_TYPE_HIGHLIGHT
        @match_pos = 0
       
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

        @filter_text = FXComboBox.new(text_view_header, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        @filter_text.connect(SEL_COMMAND){
          applyFilter()
          addFilterHistory()
        }

        @filter_text.connect(SEL_CHANGED) {
          applyFilter()
        }

       @auto_apply_cbtn = FXCheckButton.new(text_view_header, "auto-apply", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_RIGHT|LAYOUT_FILL_Y)
       

        text_box_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)

        @html_viewer = HTMLViewer.new(text_box_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        #searchflags = FXScintilla::SCFIND_WHOLEWORD|FXScintilla::SCFIND_MATCHCASE|FXScintilla::SCFIND_REGEXP|FXScintilla::SCFIND_WORDSTART
         @searchflags = FXScintilla::SCFIND_REGEXP
          @html_viewer.setSearchFlags @searchflags
      
        addHotkeyHandler(@html_viewer)
        addHotkeyHandler(@filter_text)

       # @filter_dt.connect(SEL_COMMAND) { applyFilter() }

      end

      def applyFilter
        pattern = @filter_text.text
        return if pattern.empty?
         
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'
      
        @text_matches = @html_viewer.search_text(pattern)

        
        if @text_matches.length > 0
          @match_pos_label.textColor = 'black'
          @match_pos_label.text = "1/#{@text_matches.length}"
          
          show_match_pos(0)
        end

      end

      private
      
      def show_match_pos(match_pos=nil)
        
        pos = match_pos.nil? ? 0 : match_pos
        return false if @text_matches.empty?
        return false if pos > @text_matches.length-1
        @match_pos = pos 
        pattern = @filter_text.text
         text_pos = @text_matches[pos]
         @html_viewer.gotoPos text_pos
          @html_viewer.setSel text_pos, text_pos+pattern.length
      end
      
      def show_next
        if @match_pos < @text_matches.length-1
        @match_pos += 1 
        show_match_pos @match_pos
        return true
        end
        return false
      end
      
      def show_prev
        if @match_pos > 0
        @match_pos -= 1 
        show_match_pos @match_pos
        return true
        end
        return false        
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
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'
        @filter_text.text = ''
      end

      def addHotkeyHandler(widget)
        @ctrl_pressed = false

        widget.connect(SEL_KEYPRESS) { |sender, sel, event|
          state = false
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_Return
            highlight(@filter_text.text)
            state = true # special handling of KEY_Return, because we don't want a linebreak in textbox.
          end

          if event.code == KEY_F1

            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "<ctrl-r> - Reset Filter",
                  "<ctrl-n> - Goto Next",
                  "<ctrl-shift-n> - Goto Prev"
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
              if show_next
                 @match_pos_label.text = "#{@match_pos+1}/#{@text_matches.length}"
              end
            when KEY_N
               if show_prev
                 @match_pos_label.text = "#{@match_pos+1}/#{@text_matches.length}"
               end
            when KEY_r
              resetFilter()

            end
          end
          state
        }

        widget.connect(SEL_KEYRELEASE) { |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        }
      end

    end
  end
end

