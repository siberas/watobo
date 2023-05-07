require_relative './action_select'

module Watobo #:nodoc: all
  module Gui
    module Fuzzer
      class CreateActionDlg < FXDialogBox

        def getAction()
          return @actionSelection.createAction()
        end

        def initialize(owner)
          super(owner, "Create Action", DECOR_TITLE | DECOR_BORDER, :width => 300, :height => 500)
          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

          @actionSelection = ActionSelect.new(main, self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_NONE, :padding => 0)

          buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM | LAYOUT_FILL_X | PACK_UNIFORM_WIDTH, :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
          # Accept
          accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT, FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)

          # Cancel
          FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL, FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)
        end
      end

    end
  end
end