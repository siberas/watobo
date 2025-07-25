# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class EnvFrame < FXVerticalFrame

          include Watobo::Subscriber

          def text
            @text.rawRequest
          end

          def text=(data)
            @text.setText(data)
          end

          def initialize(owner, opts)
            frame_opts = {}
            frame_opts[:opts] = opts
            super(owner, frame_opts)

            @text = Watobo::Gui::SimpleTextView.new(self, :opts => FRAME_THICK | FRAME_SUNKEN | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @text.editable = true
            @text.subscribe(:text_changed) do
              notify(:text_changed)
            end
          end
        end
      end
    end
  end
end


