# @private 
module Watobo#:nodoc: all
  module Gui
    class EditCommentDialog < FXDialogBox
      def comment()
        @textbox.to_s
      end

      def initialize(owner, chat)
        #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        super(owner, "Edit Comment - Chat #{chat.id}", DECOR_ALL, :width => 300, :height => 150)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        #  puts "create scopeframe with scope:"
        # @project.scope
        text_frame = FXVerticalFrame.new(base_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @textbox = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        @textbox.setText(chat.comment)
        @textbox.setFocus()
        @textbox.setDefault()

        @textbox.connect(SEL_KEYPRESS) { |sender, sel, event|
          if event.code == KEY_Tab
          @finishButton.setFocus()
          @finishButton.setDefault()
          true
          else
          false
          end

        }
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
