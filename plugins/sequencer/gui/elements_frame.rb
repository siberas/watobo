# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class ElementFrame < FXHorizontalFrame
          def initialize(owner, element)
            super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @element_btn = FXButton.new(self, element.name)
          end
        end

        class ElementsFrame < FXVerticalFrame


          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
          end

          def update_elements(elements = [])
            #clear

            each_child do |child|
              removeChild(child)
            end


            #@progress_bars = Hash.new
            elements.each do |element|
              ef = ElementFrame.new(self, element)
              ef.create
            end
            recalc
            update


          end
        end
      end

    end
  end
end
