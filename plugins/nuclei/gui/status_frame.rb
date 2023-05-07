# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Nuclei
      class Gui
        class StatusFrame < FXVerticalFrame
          #include Watobo::Gui
          #include Watobo::Gui::Icons

          STATE_STOPPED = 0x00
          STATE_RUNNING = 0x01
          include Watobo::Subscriber

          def armed!
            @action_button.enable
            @switcher.setCurrent 0
          end

          def disarmed!(text = 'Not Ready!')
            @error_dt.value = text
            @action_button.disable
            @switcher.setCurrent 1
          end

          def cancel
            @state = STATE_STOPPED
          end


          def initialize(owner, opts)
            super(owner, opts)

            @state = STATE_STOPPED
            progress_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @pbar = FXProgressBar.new(progress_frame, nil, 0, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK | PROGRESSBAR_HORIZONTAL)
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor = 0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)

            @action_button = FXButton.new(progress_frame, "start")
            @action_button.connect(SEL_COMMAND) { action_pressed }
            @action_button.disable

            @switcher = FXSwitcher.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y)
            info_frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X)
            @speed = FXLabel.new(info_frame, "Checks per second: -")
            @speed.disable


            @error_dt = FXDataTarget.new('Not Ready')
            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X)
            error_field = FXTextField.new(frame, 25, :target => @error_dt, :selector => FXDataTarget::ID_VALUE,
                                          :opts => TEXTFIELD_READONLY | FRAME_LINE | FRAME_THICK | LAYOUT_FILL_X | LAYOUT_RIGHT)
            error_field.borderColor = FXColor::Red
            error_field.shadowColor = FXColor::Red
            error_field.backColor = FXColor::LightGrey
            #error_field.editable = false

            @error_dt.value = "Not Ready!"


          end

          def update_progress(progress, total, speed)
            @pbar.total = total
            @pbar.progress = progress
            @speed.text = "Checks per second: #{speed}"
          end

          private

          def action_pressed
            if @state == STATE_STOPPED
              @state = STATE_RUNNING
              @action_button.text = 'cancel'
              notify(:on_start_btn)
            else
              @state = STATE_STOPPED
              @action_button.text = 'start'
              notify(:on_cancel_btn)
            end
          end
        end
      end
    end
  end
end

