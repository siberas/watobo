# @private
module Watobo#:nodoc: all
  module Gui
    class RequestBuilder < FXVerticalFrame
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def setRequest(raw_request)
        begin
        # request
          if raw_request.is_a? String
            request = Watobo::Utils.text2request(raw_request)
          else
            request = Watobo::Request.new raw_request
          end

          @editors.each do |name, item|
            e = item[:editor]
            r = e.setRequest(request)
            if r
              item[:tab_item].enable
            else
              item[:tab_item].disable
            end

          end

        rescue => bang
          puts bang
          puts bang.backtrace

        end
      end

      def highlight(pattern)
        # @text_edit.highlight(pattern)
      end

      def rawRequest
        @current.rawRequest
      end

      def parseRequest

        @current.parseRequest

      end

      def clear
        puts "* clear tabs"
        @editors.each do |name, item|
          e = item[:editor]
          r = e.clear
          item[:tab_item].disable
        end
      end

      def to_s
        s = @current.parseRequest
        puts "* [requestBox] .to_s"
      #  puts s
      # puts s.class
      #  puts s.empty?
        s
      end

      def initialize(owner, opts)
        super(owner,opts)

        @event_dispatcher_listeners = Hash.new
        @last_editor = nil

        @tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        @tab.connect(SEL_COMMAND){
          @current = @editors.to_a[@tab.current][1][:editor]
          unless @last_editor.nil?
          last_request = @last_editor.rawRequest
          @current.setRequest(last_request)
          end
          @last_editor = @editors.to_a[@tab.current][1][:editor]
        #puts @current.class
        }
        @editors = {}
        @current = nil

        add_editor("Text") do |frame|
          Watobo::Gui::RequestEditor.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        end

        add_editor("Table") do |frame|
          Watobo::Gui::TableEditorFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        end

        @current = @editors.first[1][:editor]

      end

      private

      def add_editor(tab_name, &b)
        tab_item = FXTabItem.new(@tab, tab_name, nil)
        frame = FXVerticalFrame.new(@tab, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        editor = yield(frame) if block_given?

        @editors[tab_name.to_sym] = {
          :editor => editor,
          :tab_item => tab_item
        }
        editor.subscribe(:hotkey_ctrl_enter){ notify(:hotkey_ctrl_enter) }
        editor.subscribe(:error) { |msg| notify(:error, msg) }

      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end
    end
  end
end