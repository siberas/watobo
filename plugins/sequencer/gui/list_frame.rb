# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui
        class EntryFrame < FXHorizontalFrame
          def initialize(owner, entry)
            super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            FXLabel.new(self, "Entry", nil, LAYOUT_TOP | JUSTIFY_RIGHT)
            @entry = entry
          end

        end


        class ListFrame < FXVerticalFrame

          include Watobo::Subscriber



          def update_elements(sequence)
            @elements_frame.update_elements(sequence)
          end

          def initialize(owner, opts)
            super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED | LAYOUT_MIN_WIDTH, :width => 300 )
            @entry_frames = []

            top_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)


            FXLabel.new(top_frame, "Elements", nil, LAYOUT_TOP | JUSTIFY_RIGHT)


            @add_btn = FXButton.new(top_frame, "+")
            @add_btn.connect(SEL_COMMAND) do
              puts "+ add a new entry"
              dlg = CreateElementDlg.new(self)
              if dlg.execute != 0 then
                puts "+ dlg finished"
                element = dlg.element
                puts element.class.to_s

                puts element.name
                notify(:new_element, element)

              end
            end

            @elements_frame = ElementsFrame.new(self)
            @elements_frame.subscribe(:element_selected){|element|
              @elements_frame.highlight element
              notify(:element_selected, element)
            }
            @elements_frame.subscribe(:send_element){ |element|
                notify(:send_element, element)
              }
          end


        end
      end
    end
  end
end
