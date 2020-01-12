# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class DirectoryGeneratorOptions < FXVerticalFrame

          def preferences
            { directory: @payload_dir_dt.value }
          end

          def initialize(owner, prefs)
            super(owner, prefs)


            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
            @payload_dir_dt = FXDataTarget.new('')
            # @payload_dir_dt.value = @project.payloadDirectory() if File.exist?(@project.payloadDirectory())
            @payload_dir_label = FXLabel.new(frame, "Directory:")
            payload_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            @payload_dir_text = FXTextField.new(payload_frame, 20,
                                                :target => @payload_dir_dt, :selector => FXDataTarget::ID_VALUE,
                                                :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
            @payload_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @select_btn = FXButton.new(payload_frame, "Select" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

            @select_btn.connect(SEL_COMMAND){ |sender, sel, item|
              selectPayloadDirectory
            }

          end

          private

          def selectPayloadDirectory
            workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Payload Directory", @payload_dir_dt.value)
            if workspace_dt != "" then
              if File.exist?(workspace_dt) then
                @payload_dir_dt.value = workspace_dt
                @payload_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              end
            end
          end

        end
      end
    end
  end
end
