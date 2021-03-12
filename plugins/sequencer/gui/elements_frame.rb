# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class ElementFrame < FXHorizontalFrame
          include Watobo::Subscriber

          attr :element

          def highlight(state=true)
            if state
              @element_btn.backColor = FXColor::Green
            else
              @element_btn.backColor = FXColor::LightGrey
            end
          end

          def initialize(owner, element)
            super(owner, :opts => LAYOUT_FILL_X | FRAME_SUNKEN)

            @element = element
            @enabled = FXCheckButton.new(self, "", nil, 0, JUSTIFY_LEFT | JUSTIFY_TOP | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)
            @enabled.checkState = true
            @enabled.connect(SEL_COMMAND) do
              @element.enabled = @enabled.checked? ? true : false
            end

            @element_btn = FXButton.new(self, element.name)
            @element_btn.connect(SEL_COMMAND) do
              notify(:element_selected, self)
            end

            @send_btn = FXButton.new(self, 'send', :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @send_btn.connect(SEL_COMMAND) do
              notify(:send_element, @element)
            end
          end
        end

        class ElementsFrame < FXVerticalFrame

          include Watobo::Subscriber

          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
          end

          def highlight(frame)
            each_child do |child|
              child.highlight false
            end
            frame.highlight true
          end

          def update_elements(elements = [])
            #clear

            each_child do |child|
              removeChild(child)
            end


            #@progress_bars = Hash.new
            elements.each do |element|
              ef = ElementFrame.new(self, element)
              ef.subscribe(:element_selected) { |element|
                notify(:element_selected, element)
              }
              ef.subscribe(:send_element) { |element|
                notify(:send_element, element)
              }
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
