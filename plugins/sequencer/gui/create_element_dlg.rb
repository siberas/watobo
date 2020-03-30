# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui
        class CreateElementDlg < FXDialogBox
          attr :element


          def initialize(owner)
            #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
            super(owner, "Add Entry", DECOR_ALL)
            base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
            frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

            FXLabel.new(frame, "Element Name:")
            @element_name_dt = FXDataTarget.new('')

            @element_name_txt = FXTextField.new(frame, 15,
                            :target => @element_name_dt, :selector => FXDataTarget::ID_VALUE,
                            :opts => TEXTFIELD_NORMAL | LAYOUT_SIDE_RIGHT)

            @finishButton = FXButton.new(frame, "Add", nil, nil, :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @finishButton.enable

            @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
              #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
              @element = Element.new( name: @element_name_dt.value )
              self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
            end

            @cancelButton = FXButton.new(frame, "Cancel",
                                         :target => self, :selector => FXDialogBox::ID_CANCEL,
                                         :opts => BUTTON_NORMAL | LAYOUT_RIGHT)

          end

          private
          def create
            super
            @element_name_dt.value = ""
          end
        end
      end
    end
  end
end
