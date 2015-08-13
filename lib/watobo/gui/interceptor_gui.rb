# @private 
module Watobo#:nodoc: all
  module Gui
    class InterceptEditor < FXVerticalFrame
      
      include Watobo::Constants
      include Watobo::Interceptor
      include Watobo::Gui::Utils
      
      def initialize(owner, opts)

        super(owner, opts)

        @lock = Mutex.new
        @text = nil

        @event_dispatcher_listeners = Hash.new

        text_view_header = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_HEIGHT, :height => 24, :padding => 0)

        #@auto_apply_cbtn.connect(SEL_COMMAND, method(:onInterceptChanged))

        @pmatch_btn = FXButton.new(text_view_header, "<", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y)
        @pmatch_btn.disable

        @pmatch_btn.connect(SEL_COMMAND) {
          if @textbox.numMatches > 0
            @match_pos_label.textColor = 'black'
            pos = @textbox.showPrevMatch() + 1
            @match_pos_label.text = "#{pos}/#{@textbox.numMatches}"
          else
            @match_pos_label.textColor = 'grey'
          end
        }

        @match_pos_label = FXLabel.new(text_view_header, "0/0", :opts => LAYOUT_FILL_Y)
        @match_pos_label.textColor = 'grey'

        @nmatch_btn = FXButton.new(text_view_header, ">", nil, nil, 0, FRAME_RAISED|LAYOUT_FILL_Y)
        @nmatch_btn.disable

        @nmatch_btn.connect(SEL_COMMAND) {

          @textbox.showNextMatch()
          if @textbox.numMatches > 0
            @match_pos_label.textColor = 'black'
            pos = @textbox.showNextMatch() + 1
            @match_pos_label.text = "#{pos}/#{@textbox.numMatches}"
          else
            @match_pos_label.textColor = 'grey'
          end
        }

        @filter_dt = FXDataTarget.new('')
        # @filter_text = FXTextField.new(text_view_header, 10,
        # :target => @filter_dt, :selector => FXDataTarget::ID_VALUE,
        # :opts => FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @filter_text = FXComboBox.new(text_view_header, 20, @filter_dt, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
        @filter_text.connect(SEL_COMMAND){
          applyFilter()
          addFilterHistory()
        }

        @filter_text.connect(SEL_CHANGED) {
          applyFilter()
        }
        inputFieldHotkeyHandler(@filter_text)

        @auto_select_cbtn = FXCheckButton.new(text_view_header, "auto-select", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_RIGHT|LAYOUT_FILL_Y)
        #@mode_btn = FXButton.new(text_view_header, "Highlight", :opts=> MENUBUTTON_DOWN|FRAME_RAISED|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_RIGHT|LAYOUT_FILL_Y)

        reset_button = FXButton.new(text_view_header, "&Reset", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y)
        reset_button.connect(SEL_COMMAND){ resetTextbox() }

        #-----------------------
        text_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)

        @textbox_dt = FXDataTarget.new('')

        @textbox = Watobo::Gui::TextView2.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        #  @textbox = Watobo::Gui::TextView2.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        # @textbox = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        # @textbox = FXText.new(text_frame, :target => @textbox_dt, :selector => FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @textbox.textStyle -= TEXT_WORDWRAP
        @textbox.extend Watobo::Mixins::RequestParser

        @textbox.editable = true

        @markers = []

        @record_input = false # EXPERIMENTAL !!!

        @last_cursor_pos = 0
        @start_selection_pos = 0

        @input_start = 0
        @input_len = 0

        @textbox.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|
              addStringInfo(menu_pane, sender)
              addDecoder(menu_pane, sender)
              addEncoder(menu_pane, sender)
              FXMenuSeparator.new(menu_pane)
              target = FXMenuCheck.new(menu_pane, "word wrap" )
              target.check = ( @textbox.textStyle & TEXT_WORDWRAP > 0 ) ? true : false
              target.connect(SEL_COMMAND) { |tsender, tsel, titem|
                if tsender.checked?
                  @textbox.textStyle |= TEXT_WORDWRAP
                else
                @textbox.textStyle ^= TEXT_WORDWRAP
                end
              }

              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)
            end

          end
        end

        # KEY_Return
        # KEY_Control_L
        # KEY_Control_R
        # KEY_s
        @ctrl_pressed = false

        @textbox.connect(SEL_KEYPRESS, method(:initEditKeys))

        @textbox.connect(SEL_KEYRELEASE) do |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        end

      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def empty?
        @textbox.to_s.empty?
      end

      def clear
        @textbox.setText('')
      end

      def setText(text=nil)
        return false if text.nil?
        if text.is_a? Array
        new_text = text.join
        else
          new_text = "#{text}"
        end

        @lock.synchronize do
          @text  = new_text.strip.gsub(/\r/,'')

          unless @text.empty?
          @textbox.setText @text
          end
        end
      #  @textbox.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      #@textbox.update

      end

      def parseRequest(prefs={})
        begin
          return @textbox.to_request(prefs)
        rescue SyntaxError, LocalJumpError, NameError
          notify(:error, "#{$!}")
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          notify(:error, "Could not parse request: #{$!}")
        end

        return nil
      end
      
      def to_response(prefs={})
        begin
          return @textbox.to_response(prefs)
        rescue SyntaxError, LocalJumpError, NameError
        #  puts bang
        #  puts bang.backtrace if $DEBUG
          notify(:error, "#{$!}")
        rescue => bang
        puts bang
        notify(:error, "Could not parse request: #{$!}")
        end

        return nil
      end

      private

      def recordedText
        @textbox.extractText(@input_start, @input_len)
      end

      def applyFilter
        pattern = @filter_text.text
        @textbox.reset_text
        @match_pos_label.textColor = 'grey'
        @match_pos_label.text = "0/0"
        return true if pattern == ''

        @textbox.applyFilter(pattern)
        if @textbox.numMatches > 0

          @match_pos_label.text = "1/#{@textbox.numMatches}"
          #@match_pos_label.enable
          @match_pos_label.textColor = 'black'
          @textbox.showMatch(0, :select_match => @auto_select_cbtn.checked? )
        @nmatch_btn.enable
        @pmatch_btn.enable
        else
        @nmatch_btn.disable
        @pmatch_btn.disable
        end
      #  puts "got #{matches.length} matches for pattern #{Regexp.quote(pattern)}"
      end

      def inputFieldHotkeyHandler(widget)
        @ctrl_pressed = false

        widget.connect(SEL_KEYPRESS) { |sender, sel, event|
        # puts event.code
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_Return
            applyFilter()
            @textbox.setFocus()
            @textbox.setDefault()
            @textbox.showMatch(0, :select_match => @auto_select_cbtn.checked? )
          true # special handling of KEY_Return, because we don't want a linebreak in textbox.
          end

          if @ctrl_pressed
            case event.code
            when KEY_w
              @textbox.textStyle ^= TEXT_WORDWRAP
            when KEY_n
              @textbox.showNextMatch()
              addFilterHistory()
            when KEY_N
              @textbox.showPrevMatch()
              addFilterHistory()
            when KEY_r
              @textbox.reset_filter()
            end
          end

          if event.code == KEY_F1

            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "<ctrl-r> - Reset Filter",
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
          true
          else
          false
          end
        }

        widget.connect(SEL_KEYRELEASE) { |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        }
      end

      def initEditKeys(sender, sel, event)
        #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
        if event.code == KEY_F1

          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|
              FXMenuCaption.new(menu_pane, "Hotkeys:")
              FXMenuSeparator.new(menu_pane)
              [ "<ctrl-r> - Reset Filter",
                "<ctrl-n> - Goto Next",
                "<ctrl-shift-n> - Goto Prev",
                "<ctrl-w> - Switch Wordwrap",
                "<ctrl-b> - Encode Base64",
                "<ctrl-shift-b> - Decode Base64",
                "<ctrl-u> - Encode URL",
                "<ctrl-shift-u> - Decode URL",
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
          return true if event.code == KEY_Control_L or event.code == KEY_Control_R
          if event.code == KEY_Return
            notify(:hotkey_ctrl_enter)
          true # special handling of KEY_Return, because we don't want a linebreak in textbox.
          else

            case event.code
            when KEY_w
              @textbox.textStyle ^= TEXT_WORDWRAP
            when KEY_n
              @textbox.showNextMatch()
              addFilterHistory()
            when KEY_N
              @textbox.showPrevMatch()
              addFilterHistory()
            when KEY_r
              resetTextbox()
            end

            pos = @textbox.selStartPos
            len = @textbox.selEndPos - pos

            if len == 0 then
            pos = @input_start
            len = @input_len
            end

            unless len==0
              text = @textbox.extractText(pos,len)
              rptxt = case event.code
              when KEY_u
                CGI::escape(text).strip
              when KEY_b
                Base64.encode64(text).strip
              when KEY_U
                CGI::unescape(text).strip
              when KEY_B
                Base64.decode64(text).strip
              else
              text
              end
            @textbox.replaceText(pos, len, rptxt,false)
            @textbox.setSelection(pos,rptxt.length)
            end
          false
          end
        else
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
        false
        end
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

      def resetTextbox()
        @textbox.setPrintable(@text)
        @textbox.reset_text
        @match_pos_label.text = "0/0"
        @match_pos_label.textColor = 'grey'
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

    end

    class InterceptorUI < FXTopWindow

      include Responder
      include Watobo
      include Watobo::Interceptor
      include Watobo::Gui::Icons
      def execute
        create
        show(PLACEMENT_SCREEN)
      # getApp().runModalFor(self)
      end

      # this method is obsolet! Use addRequest() instead
      def modifyRequest(request, thread)
        addRequest(request, thread)
      end

      # this method is obsolet! Use addResponse() instead
      def modifyResponse(request, thread)
        addResponse(request, thread)
      end

      def addRequest(request, thread)
        puts "* [Interceptor] addRequest"

        new_request = {
          :request => request,
          :thread => thread
        }

        @request_lock.synchronize do
        #   enable_buttons()
          @request_queue << new_request

        end

      # enable_buttons()

      end

      def addResponse(response, thread)
        response.extend Watobo::Mixin::Parser::Web10
        response.extend Watobo::Mixin::Shaper::Web10

        response.fixupContentLength()

        #  puts response

        new_response = {
          :response => response,
          :thread => thread
        }

        @response_lock.synchronize do
          @response_queue.push new_response

        end
      end

      def initialize(owner, opts)
        # Invoke base class initialize function first

        super( owner, 'Interceptor', nil, nil, DECOR_ALL|DECOR_TITLE|DECOR_BORDER|DECOR_RESIZE, 0, 0, 600, 400, 0, 0, 0, 0, 0, 0)
        self.connect(SEL_CLOSE, method(:onClose))
        self.icon = ICON_INTERCEPTOR
        #@interceptor = interceptor

        @request_list = []
        @response_list = []

        @request_queue = []
        @response_queue = []

        @request_lock = Mutex.new
        @response_lock = Mutex.new
        
        @request_box_available = true
        @response_box_available = true

        # initial frame setup
        mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)

        top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM,:height => 500)
        top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)

        #log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)

        filter_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM)
         gbframe = FXGroupBox.new(filter_frame, "Intercept", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
      #  FXLabel.new(filter_frame, "Intercept:" )
        @intercept_request = FXCheckButton.new(frame, "Requests", nil, 0,
        ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @intercept_request.connect(SEL_COMMAND, method(:onInterceptChanged))

        @intercept_response = FXCheckButton.new(frame, "Response", nil, 0,
        ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @intercept_response.connect(SEL_COMMAND, method(:onInterceptChanged))
        @filter_options_btn = FXButton.new(frame, "Options", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
        @filter_options_btn.connect(SEL_COMMAND, method(:onBtnFilterOptions))
        
        gbframe = FXGroupBox.new(filter_frame, "Rewrite", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #FXLabel.new(filter_frame, "Rewrite:" )
        @rewrite_request = FXCheckButton.new(frame, "Requests", nil, 0,
        ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @rewrite_request.connect(SEL_COMMAND, method(:onInterceptChanged))

        @rewrite_response = FXCheckButton.new(frame, "Response", nil, 0,
        ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @rewrite_response.connect(SEL_COMMAND, method(:onInterceptChanged))

 @rewrite_options_btn = FXButton.new(frame, "Options", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
        @rewrite_options_btn.connect(SEL_COMMAND){ open_rewrite_options_dialog }
       
        #@intercept_request.checkState = false
        #@intercept_response.checkState = false
        if Watobo::Interceptor.active?

          @intercept_request.checkState = Watobo::Interceptor.intercept_requests?
          @intercept_response.checkState = Watobo::Interceptor.intercept_requests?
        end

        view_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM)

        @tabBook = FXTabBook.new(view_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

        button_frame = FXHorizontalFrame.new(view_frame, LAYOUT_FILL_X)
        @tabBook.connect(SEL_COMMAND) { |sender, sel, item|
          case item
          when 0
            enable_buttons if @request_list.length > 0
          when 1
            enable_buttons if @response_list.length > 0
          end

        }
        @request_tab = FXTabItem.new(@tabBook, "Request (0)", nil)
        request_frame_outer = FXVerticalFrame.new(@tabBook, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        # request_frame = FXVerticalFrame.new(request_frame_outer, LAYOUT_FILL_X|LAYOUT_FILL_Y)

       # @requestbox = Watobo::Gui::InterceptEditor.new(request_frame_outer, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @requestbox = Watobo::Gui::RequestBuilder.new(request_frame_outer, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @response_tab = FXTabItem.new(@tabBook, "Response (0)", nil)
        response_frame_outer = FXVerticalFrame.new(@tabBook, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        #response_frame = FXVerticalFrame.new(response_frame_outer, LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding=>0)
        # @responsebox = Watobo::Gui::RequestEditor.new(response_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y )
       
        #@responsebox = Watobo::Gui::InterceptEditor.new(response_frame_outer, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @responsebox = Watobo::Gui::RequestBuilder.new(response_frame_outer, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        # @responsebox.editable = true

        @accept_button = FXButton.new(button_frame, "Accept", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
        @accept_button.connect(SEL_COMMAND, method(:onAcceptChanges))

        @discard_button = FXButton.new(button_frame, "Discard", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
        @discard_button.connect(SEL_COMMAND, method(:onDiscard))

        @drop_button = FXButton.new(button_frame, "Drop", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
        @drop_button.connect(SEL_COMMAND, method(:onDrop))

        #  log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
        #  @log_viewer = FXText.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        disable_buttons()

        # start an update timer
        @update_timer = FXApp.instance.addTimeout( 50, :repeat => true) {
          
          @request_lock.synchronize do
            unless @request_queue.empty?
              @request_list.concat @request_queue
              @request_queue.clear
              @request_tab.text = "Request (#{@request_list.length})"
            end

            if @request_list.length > 0 and @request_box_available
              @requestbox.setRequest @request_list.first[:request]
              @request_box_available = false
            end

          end
          
          @response_lock.synchronize do
            unless @response_queue.empty?
              @response_list.concat @response_queue
              @response_queue.clear
              @response_tab.text = "Response (#{@response_list.length})"
            end

            if @response_list.length > 0 and @response_box_available
             # @responsebox.setText @response_list.first[:response]
              @responsebox.setRequest @response_list.first[:response]
              @response_box_available = false
            end

          end
          update_buttons
        }

      end

      def releaseAll()
        #  puts "* closing interceptor"
        #  puts "* disable all interceptions"
        #@project.intercept_request = false
        #@project.intercept_response = false
        #  puts "* release all interceptions ..."
        @request_list.each do |ir|
          ir[:thread].run
        end
        @response_list.each do |ir|
          ir[:thread].run
        end

      end

      private

      def onAcceptChanges(sender, sel, ptr)
        if @tabBook.current == 0 then

          begin
            @request_lock.synchronize do
              request = @request_list.first
              if not request.nil?
                request[:request].clear
                request[:request].concat @requestbox.parseRequest
                @requestbox.clear
                @request_box_available = true
                Watobo.print_debug( self.class.to_s, "release thread #{request[:thread]}")
                request[:thread].run
                @request_list.shift
                @request_tab.text = "Request (#{@request_list.length})"
              #getNextRequest()
              else
                puts "* [INTERCEPTOR] NOTHING TO RELEASE"
              end
            end
          rescue => bang
            puts "!!! Error"
            puts bang
          end
        else
          begin
            @response_lock.synchronize do
              response = @response_list.first
              if not response.nil?
                response[:response].clear
                #new_response = @responsebox.to_response(:update_content_length => true)
                new_response = @responsebox.parseRequest
                #puts new_response.class
                response[:response].concat new_response
                #puts new_response
                response[:thread].run
                @responsebox.clear
                @response_box_available = true
                @response_list.shift
                @response_tab.text = "Response (#{@response_list.length})"
              # getNextResponse()
              end
            end
          rescue => bang
            puts "!!! Error"
            puts bang
            puts bang.backtrace
          end
        end

      end

      def onDrop(sender, sel, ptr)
        if @tabBook.current == 0 then
          @request_lock.synchronize do
          request = @request_list.first
          if request
            request[:request].clear
            request[:thread].kill
          @request_list.shift
          @requestbox.clear
          @request_box_available = true
          end
          @request_tab.text = "Request (#{@request_list.length})"
          end
          #getNextRequest()
        else
          @response_lock.synchronize do
          response = @response_list.first
          if response
            response[:response].clear
            response[:thread].kill
          @response_list.shift
          @responsebox.clear
          @response_box_available = true
          end
           @response_tab.text = "Response (#{@response_list.length})"
         # getNextResponse()
end
        end
      end

      def onDiscard(sender, sel, ptr)
        if @tabBook.current == 0 then
          @request_lock.synchronize do
          request = @request_list.first
          request[:thread].run if request
          @request_list.shift
          @requestbox.clear
          @request_box_available = true
          @request_tab.text = "Request (#{@request_list.length})"
          
          end
          #getNextRequest()
        else
          @response_lock.synchronize do
          response = @response_list.first
          response[:thread].run if response
          @response_list.shift
          @responsebox.clear
          @response_box_available = true
          @response_tab.text = "Response (#{@response_list.length})"
          #getNextResponse()
          end
        end
      end

      def onDiscardAll(sender, sel, ptr)

      end

      #    def onHide
      #      #  puts "* hiding interceptor"
      #      Watobo::Interceptor.intercept_mode = INTERCEPT_NONE
      #      @mutex.synchronize {
      #        @cv.signal
      #      }
      #    end

      def onClose(sender, sel, ptr)
        puts "* closing Interceptor UI"
        puts "+ stop intercepting"
        Watobo::Interceptor.intercept_mode = INTERCEPT_NONE
        Watobo::Interceptor.rewrite_mode = REWRITE_NONE
        puts "+ release all interceptions"
        releaseAll()
        #getApp().stopModal(self, 1)
        puts "_"
        
        self.hide()
      end

      def enable_buttons
        @accept_button.enabled = true
        @discard_button.enabled = true
        @drop_button.enabled = true
      end

      def disable_buttons
        @accept_button.enabled = false
        @discard_button.enabled = false
        @drop_button.enabled = false
      end

      def update_buttons
        if @tabBook.current == 0 then
          @request_lock.synchronize do
            if @request_list.length > 0
              enable_buttons
            else
              disable_buttons
            end
          end

        else
          @response_lock.synchronize do
            if @response_list.length > 0
              enable_buttons
            else
              disable_buttons
            end
          end
        end
      end

      def onBtnFilterOptions(sender, sel, ptr)

        dlg = Watobo::Gui::InterceptorFilterSettingsDialog.new( self,
        :request_filter_settings => Interceptor.proxy.getRequestFilter(),
        :response_filter_settings => Interceptor.proxy.getResponseFilter()
        )
        if dlg.execute != 0 then
        # TODO: Apply interceptor settings
        Interceptor.proxy.setRequestFilter(dlg.getRequestFilter)
        Interceptor.proxy.setResponseFilter(dlg.getResponseFilter)
        end

      end
      
      def open_rewrite_options_dialog
        dlg = Watobo::Gui::RewriteRulesDialog.new( self )
        if dlg.execute != 0 then
        # TODO: Apply interceptor settings
        Interceptor::RequestCarver.set_carving_rules dlg.request_rules
        Interceptor::ResponseCarver.set_carving_rules dlg.response_rules
        end
      end

      def onInterceptChanged(sender, sel, ptr)
        begin
         # unless @interceptor.nil? then
            mode = @intercept_response.checked? ? INTERCEPT_RESPONSE : 0
            mode |= @intercept_request.checked? ? INTERCEPT_REQUEST : 0
            #Watobo::Interceptor.intercept_mode = @intercept_response.checked? ? INTERCEPT_RESPONSE : 0
           # Watobo::Interceptor.intercept_mode |= @intercept_request.checked? ? INTERCEPT_REQUEST : 0
          #puts Watobo::Interceptor.intercept_mode
         # puts "New Proxy Mode: #{mode}"
          Watobo::Interceptor.intercept_mode = mode
          
          mode = @rewrite_request.checked? ? REWRITE_REQUEST : 0
          mode |= @rewrite_response.checked? ? REWRITE_RESPONSE : 0
          Watobo::Interceptor.rewrite_mode = mode
         # end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

    end

    class InterceptorFilterSettingsDialog < FXDialogBox

      include Responder
      include Watobo::Interceptor
      
      def getRequestFilter()
        @request_filter
      end

      def getResponseFilter()
        @response_filter
      end

      def initialize(owner, settings = {} )
        super(owner, "Interceptor Settings", DECOR_ALL, :width => 300, :height => 425)

        @request_filter = { }

        @response_filter = { }

        @request_filter.update settings[:request_filter_settings]
        @response_filter.update settings[:response_filter_settings]

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @tabbook = FXTabBook.new(base_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        buttons_frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X)
        @req_opt_tab = FXTabItem.new(@tabbook, "Request Options", nil)
        frame = FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_window = FXScrollWindow.new(frame, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @req_opt_frame = FXVerticalFrame.new(scroll_window, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @resp_opt_tab = FXTabItem.new(@tabbook, "Response Options", nil)
        frame= FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_window = FXScrollWindow.new(frame, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @resp_opt_frame = FXVerticalFrame.new(scroll_window, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        initRequestFilterFrame()
        updateRequestFilterFrame()

        initResponseFilterFrame()
        updateResponseFilterFrame()

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

      private

      def onAccept(sender, sel, event)
        #TODO: Check if regex is valid
        @request_filter[:method_filter] = @method_filter_dt.value
        @request_filter[:negate_method_filter] = @neg_method_filter_cb.checked?
        @request_filter[:negate_url_filter] = @neg_url_filter_cb.checked?
        @request_filter[:url_filter] = @url_filter_dt.value
        @request_filter[:file_type_filter] = @ftype_filter_dt.value
        @request_filter[:negate_file_type_filter] = @neg_ftype_filter_cb.checked?

        @request_filter[:parms_filter] = @parms_filter_dt.value
        @request_filter[:negate_parms_filter] = @neg_parms_filter_cb.checked?

        @response_filter[:content_type_filter] = @content_type_filter_dt.value
        @response_filter[:negate_content_type_filter] = @neg_ctype_filter_cb.checked?

        @response_filter[:response_code_filter] =  @rcode_filter_dt.value
        @response_filter[:negate_response_code_filter] = @neg_rcode_filter_cb.checked?

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

      def updateRequestFilterFrame()
        @parms_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @url_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @ftype_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @method_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def updateResponseFilterFrame()
        @content_type_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @rcode_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      # @neg_rcode_filter_cb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      # @neg_ctype_filter_cb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def initResponseFilterFrame()

        gbframe = FXGroupBox.new(@resp_opt_frame, "Content Type", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP Content-Type. E.g., '(text|script)'"
        fxtext.setText(text)
        @content_type_filter_dt = FXDataTarget.new('')
        @content_type_filter_dt.value = @response_filter[:content_type_filter]
        @content_type_filter = FXTextField.new(frame, 20, :target => @content_type_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_ctype_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_ctype_filter_cb.checkState = @response_filter[:negate_content_type_filter]

        gbframe = FXGroupBox.new(@resp_opt_frame, "Response Code", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP Content-Type. E.g., '200'"
        fxtext.setText(text)
        @rcode_filter_dt = FXDataTarget.new('')
        @rcode_filter_dt.value = @response_filter[:response_code_filter]

        @rcode_filter = FXTextField.new(frame, 20, :target => @rcode_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_rcode_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_rcode_filter_cb.checkState = @response_filter[:negate_response_code_filter]

      end

      def initRequestFilterFrame()
        gbframe = FXGroupBox.new(@req_opt_frame, "URL Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular Expression Filter For URL. E.g., '.*www.mysite.com.*login.php'"
        fxtext.setText(text)

        @url_filter_dt = FXDataTarget.new('')
        @url_filter_dt.value = @request_filter[:url_filter]
        @url_filter = FXTextField.new(frame, 20, :target => @url_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_url_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_url_filter_cb.checkState = false
        @neg_url_filter_cb.checkState = @request_filter[:negate_url_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "Method Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP method. E.g., '(get|PoSt)'"
        fxtext.setText(text)
        @method_filter_dt = FXDataTarget.new('')
        @method_filter_dt.value = @request_filter[:method_filter]
        @method_filter = FXTextField.new(frame, 20, :target => @method_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_method_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_method_filter_cb.checkState = @request_filter[:negate_method_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "Parm Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular Expression Filter For Parameter Names. E.g., for intercepting requests containing parameters beginning with 'act' use the regex pattern '^act.*' (without single quotes)"
        fxtext.setText(text)
        @parms_filter_dt = FXDataTarget.new('')
        @parms_filter_dt.value = @request_filter[:parms_filter]
        @parms_filter = FXTextField.new(frame, 20, :target => @parms_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_parms_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_parm_filter_cb.checkState = false
        @neg_parms_filter_cb.checkState = @request_filter[:negate_parms_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "File Type Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for file types by its extension. E.g., for intercepting requests where file type is PHP use '^php$' (without single quotes)"
        fxtext.setText(text)
        @ftype_filter_dt = FXDataTarget.new('')
        @ftype_filter_dt.value = @request_filter[:file_type_filter]
        @ftype_filter = FXTextField.new(frame, 20, :target => @ftype_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_ftype_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_parm_filter_cb.checkState = false
        @neg_ftype_filter_cb.checkState = @request_filter[:negate_file_type_filter]
      end
    end
  #
  end
end

if __FILE__ == $0
  class TestGui < FXMainWindow
    def initialize(app)
      # Call base class initializer first
      super(app, "Test Application", :width => 800, :height => 600)
      frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
      Watobo::Gui::InterceptorUI.new(frame, nil, nil)
    end

    # Create and show the main window
    def create
      super                  # Create the windows
      show(PLACEMENT_SCREEN) # Make the main window appear

    end
  end
  #   application = FXApp.new('LayoutTester', 'FoxTest')
  TestGui.new($application)
$application.create
$application.run
end
