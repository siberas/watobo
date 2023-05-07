require_relative './create_action_dlg'
require_relative './create_filter_dlg'
require_relative './create_fuzzer_dlg'
require_relative './create_generator_dlg'
# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer
      class CreateFuzzerDlg < FXDialogBox

        def tag
          @tag_dt.value
        end

        def initialize(owner)
          super(owner, "Create New Tag", DECOR_TITLE | DECOR_BORDER)
          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          FXLabel.new(frame, "Enter Label For Tag:")
          input = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          @tag_dt = FXDataTarget.new('')
          @tag_text = FXTextField.new(input, 1, :target => @tag_dt, :selector => FXDataTarget::ID_VALUE,
                                      :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_COLUMN)

          FXLabel.new(main, "Note:\nTo define the position in the request enclose the tag name\nbetween '%%', eg. '%%tag%%'.\nIt will turn green if the given tag name is correct.\n" +
              "Don't forget to specify a generator!").justify = JUSTIFY_LEFT

          @tag_text.setFocus()
          @tag_text.setDefault()

          @tag_dt.connect(SEL_COMMAND) {
            @accept_btn.setFocus()
            @accept_btn.setDefault()
          }
          buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM | LAYOUT_FILL_X | PACK_UNIFORM_WIDTH,
                                          :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
          # Accept
          @accept_btn = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT, FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)

          # Cancel
          FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL, FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)
        end
      end

    end
  end
end
