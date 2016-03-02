# @private 
module Watobo#:nodoc: all
  module Gui

    SEL_TYPE_GREP = 0
    SEL_TYPE_HIGHLIGHT = 1
    class TextViewer < FXVerticalFrame

      attr_accessor :max_len
      def style=(new_style)
        @simple_text_view.style = new_style
      end

      def editable=(value)
        @simple_text_view.editable = value
      end

      def setText(text, prefs={})
        
        normalized_text = text
        if text.is_a? String
           normalized_text = text.gsub(/[^[:print:]]/,".")
        elsif text.respond_to? :has_body?
          if text.content_type =~ /(xml)/
            doc = Nokogiri::XML(text.body, &:noblanks)
            fbody = doc.to_xhtml( indent:3, indent_text:" ")
            normalized_text = text.headers.map{|h| h.strip }.join("\n")
            normalized_text << "\n\n"
            unless fbody.to_s.empty?
            normalized_text << fbody.to_s
            else
              normalized_text = text
            end
          end
        end
        
        @text = normalized_text
        #@text = text
        @simple_text_view.max_len = @max_len
        @simple_text_view.setText(text, prefs)
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
        @max_len = -1 #5000
        @filter_mode = SEL_TYPE_HIGHLIGHT
        @cur_match_pos = 0
        @text_dt = FXDataTarget.new('')
        @filter_dt = FXDataTarget.new('')

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
        puts pattern.length
        puts pattern
        begin
        @cur_match_pos = 0
        @simple_text_view.max_len = 0

        @match_pos_label.textColor = 'black'

        @simple_text_view.setText(@text)
        @simple_text_view.highlight(pattern)
        @match_pos_label.text = "0/#{@simple_text_view.numMatches()}"

        @simple_text_view.makeMatchVisible(0)

        @match_pos_label.text = "1/#{@simple_text_view.numMatches()}" if @simple_text_view.numMatches() > 0
        rescue => bang
          puts bang
        end

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

    class RequestViewer < FXVerticalFrame

      attr_accessor :max_len
      def setText(text)
        @text = text
        @textviewer.max_len = @max_len
        index = @tabBook.current
        @viewers[index].setText(text)
      end

      def setFontSize(size)
        @textviewer.setFont(nil, size)
      end

      def getText
        index = @tabBook.current
        @viewers[index].getText()
      end

      def highlight(pattern)
        begin
          index = @tabBook.current
          @viewers[index].highlight(pattern)
        rescue
        end
      end

      def initialize(owner, opts)
        super(owner, opts)
        @tabbook = nil
        @viewers = []
        @text = ''
        @max_len = -1 #5000

        @tabBook = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        @tabBook.connect(SEL_COMMAND) {
          begin
            getApp().beginWaitCursor()
            setText(@text)
          ensure
            getApp().endWaitCursor()
          end
        }
        textviewer_tab = FXTabItem.new(@tabBook, "Text", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @textviewer = TextViewer.new(tab_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y,:padding => 0)
        @textviewer.style = 1
        @textviewer.editable = false

        @viewers.push @textviewer

        FXTabItem.new(@tabBook, "Hex", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @hexViewer = HexViewer.new(tab_frame)
        @viewers.push @hexViewer
        
        FXTabItem.new(@tabBook, "Table", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @viewers << Watobo::Gui::TableEditorFrame.new(tab_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
      end

    end

    class ResponseViewer < FXVerticalFrame

      include Watobo::Gui::Utils

      attr_accessor :max_len, :auto_filter
      def setText(text, prefs={})
        
        @text = text
        @textviewer.max_len = @max_len
        index = @tabBook.current

        @viewers[index].setText(text)
     #  @viewers.map{|v| v.setText(text)}
      # @textviewer.applyFilter if cp[:filter] == true

      end

      def setFontSize(size)
        @textviewer.setFont(nil, size)
      end

      def getText
        index = @tabBook.current
        @viewers[index].getText()
      end

      def highlight(pattern)
        begin
          index = @tabBook.current
          @viewers[index].highlight(pattern)
        rescue
        end
      end

      def initialize(owner, opts)
        super(owner, opts)

        @tabbook = nil
        @viewers = []
        @text = ''
        @max_len = 5000

        @auto_filter = false

        @tabBook = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        @tabBook.connect(SEL_COMMAND) {
          begin
            getApp().beginWaitCursor()
            setText(@text)
          ensure
            getApp().endWaitCursor()
          end
        }

        @text_dt = FXDataTarget.new('')

        textviewer_tab = FXTabItem.new(@tabBook, "Text", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @textviewer = TextViewer.new( tab_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
       # @textviewer = TextView2.new( tab_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

        @textviewer.style = 2
        @textviewer.editable = false
        #   @textviewer.target = @text_dt
        #  @textviewer.selector = FXDataTarget::ID_VALUE

        @viewers << @textviewer

        taglessviewer_tab = FXTabItem.new(@tabBook, "Tagless", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        tagless_frame = FXVerticalFrame.new(tab_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
        #text_view_header = FXHorizontalFrame.new(tagless_frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)
        @taglessviewer = TaglessViewer.new(tagless_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @viewers << @taglessviewer

        FXTabItem.new(@tabBook, "Hex", nil)
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @hexViewer = HexViewer.new(tab_frame)
        @viewers << @hexViewer
        
        FXTabItem.new(@tabBook, "HTML", nil)       
        @html_viewer = HTMLViewerFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @viewers << @html_viewer
        
        FXTabItem.new(@tabBook, "Custom", nil)       
        @viewers << CustomViewer.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        
      end

    end
  ###################### end of namespace ############################
  end
end
