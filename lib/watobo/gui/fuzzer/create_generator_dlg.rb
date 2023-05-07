require_relative './fuzzer_gen_select'
# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer
      class CreateGeneratorDlg < FXDialogBox


        def getGenerator(fuzzer)
          return @fuzzerSelection.createGenerator(fuzzer)
        end

        def initialize(owner)
          super(owner, "Create Generator", DECOR_TITLE | DECOR_BORDER)
          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_NONE, :padding => 0)

          @fuzzerSelection = FuzzerGenSelect.new(main, self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_NONE, :padding => 0)

          buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM | LAYOUT_FILL_X | PACK_UNIFORM_WIDTH,
                                          :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
          # Accept
          accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
                                FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)

          # Cancel
          FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
                       FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT | LAYOUT_CENTER_Y)
        end
      end
    end
  end
end