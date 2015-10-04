# @private 
module Watobo#:nodoc: all
  module Gui
    class ConversationTableCtrl < FXVerticalFrame

      include Watobo::Constants
      include Watobo::Gui::Icons
      def table=(table)
        @table = table
        @table.subscribe(:table_changed) { update_info }
      end

      def initialize(owner, opts)
        super(owner, opts )
        @table = nil
        @tabBook = FXTabBook.new(self, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_RIGHT, :padding => 0)

        docfilter_tab = FXTabItem.new(@tabBook, "Doc Filter", nil)

        docfilter_frame = FXHorizontalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

        @foption_nopix = FXCheckButton.new(docfilter_frame, "excl. pics", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_nopix.setCheck(true)
        @foption_nodocs = FXCheckButton.new(docfilter_frame, "excl. docs", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_nodocs.setCheck(true)
        @foption_nojs = FXCheckButton.new(docfilter_frame, "excl. javascript", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_nojs.setCheck(true)
        @foption_nocss = FXCheckButton.new(docfilter_frame, "excl. style sheets", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_nocss.setCheck(true)

        search_tab = FXTabItem.new(@tabBook, "Text Filter", nil)

        search_frame = FXHorizontalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

        FXButton.new(search_frame, "Clear", nil, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND) { clear_text_filter }

        @text_filter = FXTextField.new(search_frame, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)
        # filterOptionsFrame =FXHorizontalFrame.new(fbox, LAYOUT_FILL_X)
        @foption_url = FXCheckButton.new(search_frame, "URL", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_url.setCheck(true)
        @foption_url.connect(SEL_COMMAND){ update_text_filter }
        @foption_req = FXCheckButton.new(search_frame, "Full Request", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_req .connect(SEL_COMMAND){ update_text_filter }
        @foption_res = FXCheckButton.new(search_frame, "Full Response", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @foption_res.connect(SEL_COMMAND){ update_text_filter }

        options_tab = FXTabItem.new(@tabBook, "Options", nil)
        options_frame = FXHorizontalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @table_option_autoscroll = FXCheckButton.new(options_frame, "autoscroll", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_autoscroll.setCheck(true)

        @table_option_unique = FXCheckButton.new(options_frame, "unique chats", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_unique.setCheck(false)

        @table_option_scope = FXCheckButton.new(options_frame, "scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_scope.setCheck(false)

        @table_option_hidetested_cb = FXCheckButton.new(options_frame, "hide tested", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_hidetested_cb.setCheck(false)
        
        @table_option_ok_only = FXCheckButton.new(options_frame, "200 only (Response)", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_ok_only.setCheck(false)
        
        @table_option_text_only = FXCheckButton.new(options_frame, "text content-type only (Response)", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
        @table_option_text_only.setCheck(false)


        @table_option_autoscroll.connect(SEL_COMMAND) {
          @table.autoscroll = @table_option_autoscroll.checked? unless @table.nil?
        }

        #applyFilterButton = FXButton.new(conversation_frame, "Apply", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
        button_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)
        FXButton.new(button_frame, "Apply", nil, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND) { apply_filter }
        #FXButton.new(docfilter_button_frame, "Clear", nil, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND, method(:onClear))

        @text_filter.connect(SEL_COMMAND){
          apply_filter
        }

        FXButton.new(button_frame, "", ICON_BTN_UP, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND) {
          @table.scrollUp() unless @table.nil?
        }

        FXButton.new(button_frame, "", ICON_BTN_DOWN, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND) {
          @table.scrollDown() unless @table.nil?
        }

        @info_txt = FXLabel.new( button_frame, "0/0", :opts => LAYOUT_RIGHT)
        
        @tabBook.connect(SEL_LEFTBUTTONRELEASE){
           x = getApp.activeWindow.x + self.x + self.parent.x + self.parent.parent.x + self.parent.parent.parent.x
    y = getApp.activeWindow.y + self.y + self.parent.y + self.parent.parent.y + self.parent.parent.parent.y + self.parent.parent.parent.parent.y
      FXMenuPane.new(self) do |menu_pane|
        frame = FXVerticalFrame.new(menu_pane, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        10.times do |i|
          FXLabel.new(frame, "Label #{i}")
        end
        menu_pane.create
        #menu_pane.popup(nil, x, y, 200, 200)
        menu_pane.popup(nil, x, y)
        app.runModalWhileShown(menu_pane)
        puts "done!"
      end
        }
      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def filter_settings
        doctype_filter = []
        doctype_filter.concat(Watobo::Conf::Gui.fext_img) if @foption_nopix.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_docs) if @foption_nodocs.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_javascript) if @foption_nojs.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_style) if @foption_nocss.checked?

        text = @text_filter.enabled? ? @text_filter.text : ""

        fs = {
          :show_scope_only => @table_option_scope.checked?,
          :text => text,
          :url => @foption_url.checked?,
          :request => @foption_req.checked?,
          :response => @foption_res.checked?,
          :hide_tested => @table_option_hidetested_cb.checked?,
          :doc_filter => doctype_filter,
          :unique => @table_option_unique.checked?,
          :ok_only => @table_option_ok_only.checked?,
          :text_only => @table_option_text_only.checked?
        }
        fs
      end

      private

      def update_info
        if @table.respond_to? :num_total
          @info_txt.text = "#{@table.num_visible}/#{@table.num_total}"
        end
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
            update_info
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

      def filter_settings
        doctype_filter = []
        doctype_filter.concat(Watobo::Conf::Gui.fext_img) if @foption_nopix.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_docs) if @foption_nodocs.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_javascript) if @foption_nojs.checked?
        doctype_filter.concat(Watobo::Conf::Gui.fext_style) if @foption_nocss.checked?

        text = @text_filter.enabled? ? @text_filter.text : ""
        unless text.empty?
          begin
            "test for valid regex".match(/#{text}/)
          rescue => bang
            text = Regexp.quote(@text_filter.text)
          end
        end

        fs = {
          :show_scope_only => @table_option_scope.checked?,
          :text => text,
          :url => @foption_url.checked?,
          :request => @foption_req.checked?,
          :response => @foption_res.checked?,
          :hide_tested => @table_option_hidetested_cb.checked?,
          :doc_filter => doctype_filter,
          :unique => @table_option_unique.checked?
        }
        fs
      end

    end
  end
end