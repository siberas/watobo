module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui

        class TweakFrame < FXVerticalFrame

          # returns enabled tweaks [Array]
          def tweaks
            @tweakTable.tweaks.select {|t| t.enabled?}
          end



          def initialize(owner, opts)
            super(owner, opts)

            #   frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            ctrl_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP)

            @add_btn = FXButton.new(ctrl_frame, "Add", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @del_btn = FXButton.new(ctrl_frame, "Del", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @up_btn = FXButton.new(ctrl_frame, "Up", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @down_btn = FXButton.new(ctrl_frame, "Down", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @del_btn.disable
            @up_btn.disable
            @down_btn.disable

            @add_btn.connect(SEL_COMMAND) {|sender, sel, item|
              dlg = Watobo::Plugin::Invader::Gui::CreateTweakDlg.new(self)
              if dlg.execute != 0 then
                @tweakTable.add_tweak dlg.get_tweak

              #else
              #  puts "CANCELED"
              end
            }

            @del_btn.connect(SEL_COMMAND) { disable_buttons; @tweakTable.delete_selected }
            @up_btn.connect(SEL_COMMAND) { @tweakTable.up_selected }
            @down_btn.connect(SEL_COMMAND) { @tweakTable.down_selected }

            frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
            sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
            @tweakTable = TweakTable.new(sunken, :opts => TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)

            @tweakTable.subscribe(:tweak_selected) do |tweak|
              if tweak.nil?
                @del_btn.disable
              else
                @del_btn.enable
              end
            end

          end

          private

          def disable_buttons
            @del_btn.disable
            @up_btn.disable
            @down_btn.disable
          end

        end
      end
    end
  end
end
