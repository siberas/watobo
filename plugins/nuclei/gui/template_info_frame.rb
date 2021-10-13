# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Nuclei
      class Gui

        class TemplateInfoFrame < FXVerticalFrame

          def update_item(item)
            @template = item
            update_template
          end

          def initialize(owner, opts)
            super(owner, opts)

            @template = nil
            box = FXGroupBox.new(self, "Template Definition", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X | LAYOUT_FILL_Y, 0, 0, 0, 0)
            @template_file = FXLabel.new(box, "Filename: ")

            frame = FXVerticalFrame.new(box,:opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_Y| FRAME_SUNKEN | FRAME_THICK, :padding => 0)
            @template_txt = FXText.new(frame, :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @template_txt.editable = false
          end

          private

          def update_template
            return false if @template.nil?
            @template_file.text = "Filename: #{@template.filename}"
            @template_txt.setText @template.template.to_yaml
          end
        end


      end
    end
  end
end
