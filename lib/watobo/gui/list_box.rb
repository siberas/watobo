# @private 
module Watobo #:nodoc: all
  module Gui
    class ListBox < FXGroupBox
      def to_a
        a=[]
        @list.each do |i|
          a << i.to_s
        end
        a
      end

      def set(list)
        @list.clearItems
        list.each do |le|
          addPattern(le)
        end
      end

      def append(list)
        if list.is_a? Array
          list.each do |e|
            addPattern(e) if e.is_a? String
          end
        elsif list.is_a? String
          addPattern(list)
        else
          raise ArgumentError, "Need String or Array"
        end
      end

      def removePattern(pattern)
        index = @list.currentItem
        if index >= 0
          @list.removeItem(index)
        end
      end

      def addPattern(pattern)
        if pattern != "" then
          pattern_ok, *error = Watobo::Utils.checkRegex(pattern)
          if pattern_ok == true
            item = @list.appendItem("#{pattern}")
            @list.setItemData(item, pattern)
            @list.sortItems()

          else
            FXMessageBox.information(self, MBOX_OK, "Wrong Path Format", "Path must be a Regex!!!\nError: #{error.join('\n')}")
          end
        end
      end

      def initialize(owner, title="", info_text="", opts= LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X)
        gbframe = super(owner, title, opts, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)

        unless info_text.empty?
          fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
          fxtext.backColor = fxtext.parent.backColor
          fxtext.disable
          text = "#{info_text}"
          fxtext.setText(text)
        end

        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        #@text = FXTextField.new(input_frame, 20, :target => @expath_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @text = FXTextField.new(input_frame, 20, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @rem_btn = FXButton.new(input_frame, "Remove", :opts => BUTTON_NORMAL|BUTTON_DEFAULT|LAYOUT_RIGHT)
        @add_btn = FXButton.new(input_frame, "Add", :opts => BUTTON_NORMAL|BUTTON_DEFAULT|LAYOUT_RIGHT)

        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @list.numVisible = 5

        @list.connect(SEL_COMMAND) { |sender, sel, item|
          @text.text = sender.getItemText(item)
          @text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }

        @rem_btn.connect(SEL_COMMAND) { |sender, sel, item|
          removePattern(@text.text) if @text.text != ''
          @text.text = ''
          @text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }

        @text.connect(SEL_COMMAND) {
          @add_btn.setFocus()
          # @add_btn.setDefault()

        }

        @add_btn.connect(SEL_COMMAND) { |sender, sel, item|

          addPattern(@text.text) if @text.text != ''
          @text.text = ''
          @text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @text.setFocus()
          #@text.setDefault()
        }
      end
    end
  end
end