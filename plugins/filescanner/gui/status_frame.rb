# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Filescanner
      class Gui
        class StatusFrame < FXHorizontalFrame
          #include Watobo::Gui
          #include Watobo::Gui::Icons

          include Watobo::Subscriber

          def armed
            @start_button.enable
          end

          def initialize(ctrl, owner, opts)
            super(owner, opts)

            @ctrl = ctrl
            progress_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @pbar = FXProgressBar.new(progress_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)

            @speed = FXLabel.new(progress_frame, "Checks per second: -")
            @speed.disable

            @start_button = FXButton.new(self, "start")
            @start_button.connect(SEL_COMMAND){ notify(:start) }
            @start_button.disable

            @ctrl.subscribe(:armed){ @start_button.enable }
            @ctrl.subscribe(:disarmed){ @start_button.disable }
          end

          def update_progress(progress, total, speed)
            @pbar.total = total
            @pbar.progress = progress
            @speed.text = "Checks per second: #{speed}"
          end

        end
      end
    end
  end
end

