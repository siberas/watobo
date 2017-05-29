# @private
module Watobo #:nodoc: all
  module Plugin
    class Sniper
      class Gui
        class TargetsFrame < FXVerticalFrame

          def initialize(parent, opts)
            super(parent, opts)

            targets_gb = FXGroupBox.new(self, "Target URLs", FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            frame = FXHorizontalFrame.new(targets_gb, :opts => LAYOUT_FILL_X)
            FXLabel.new(frame,"Targets: ")

            targets_frame = FXVerticalFrame.new(targets_gb, :opts => FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
            @targets_list = FXText.new(targets_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)


          end
        end
      end
    end
  end
end
