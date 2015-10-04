# @private 
module Watobo#:nodoc: all
  module Plugin
    class WShell
      class Gui < Watobo::PluginGui

        window_title "WATOBO Shell (experimental)"
        icon_file "wsh.ico"

        def initialize()
          super()

          @history = []
          @history_pos = 0

          hs_green = FXHiliteStyle.new
          # hs_green.normalForeColor = FXRGBA(255,255,255,255) 
          # hs_green.normalForeColor = FXRGBA(0,255,0,1)   
          #hs_green.normalBackColor = FXRGBA(0,255,0,1)   
          hs_green.style = FXText::STYLE_BOLD

          hs_red = FXHiliteStyle.new
          hs_red.normalForeColor = FXRGBA(255,0,0,255) 
          #hs_red.normalBackColor = FXRGBA(255,0,0,1)   
          hs_red.style = FXText::STYLE_BOLD

          frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          output_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
          @output = FXText.new(output_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @output.editable = false
          @output.styled = true
          #@font = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD)
          @output.setFont(FXFont.new(getApp(), "courier", 10,  FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
          @output.hiliteStyles = [ hs_green, hs_red ]

          @output.appendStyledText Watobo::Plugin::WShell::HELP_TEXT, 1

          FXLabel.new(frame, "Enter 'help' for more information.")

          cmd_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
          @cmd = FXTextField.new(cmd_frame, 25, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_LEFT)
          @cmd.connect(SEL_COMMAND){ run_cmd }

          @cmd.connect(SEL_KEYPRESS) do |sender, sel, event|
            fin = false
            if event.code == KEY_Up
              @history_pos -=1 if @history_pos > 0
              set_history_cmd
              fin = true
            elsif event.code == KEY_Down
              @history_pos += 1 if @history_pos < @history.length-1
              set_history_cmd
              fin = true
            end
            fin
          end

          @cmd.setFocus()
          @cmd.setDefault()

          @cmd_btn = FXButton.new(cmd_frame, "run")

          @cmd_btn.connect(SEL_COMMAND){ run_cmd }

        end

        private

        def set_history_cmd()
          @cmd.text = @history[@history_pos]
        end

        def run_cmd
          Thread.new{
            runOnUiThread do
              cmd = @cmd.text.strip
              unless cmd.empty?
                if cmd =~ /^help$/i
                  #  @output.appendText(Watobo::Plugin::WShell.help)
                  @output.appendStyledText Watobo::Plugin::WShell::HELP_TEXT, 2
                  @cmd.text = ''
                else
                  @output.appendStyledText ">> #{cmd}\n", 2
                  @cmd.enabled = false
                  @cmd.backColor = @cmd.parent.backColor
                  begin
                    @history << cmd unless @history.include? cmd
                    @history.shift if @history.length > 20
                    # set history_pos to length, because it will be reduced before it will be
                    # displayes
                    @history_pos = @history.length

#                    command = "out = StringIO.new; out << #{cmd}; out.string"
                    command = cmd
                    r = eval(command)
                    @output.appendStyledText "---\n#{r}\n---\n", 1

                  rescue SyntaxError, LocalJumpError, NameError => e
                    @output.appendStyledText ">> #{e}\n", 2
                  rescue => bang
                    puts bang.backtrace
                    @output.appendStyledText ">> #{bang}\n#{bang.backtrace}", 2

                  end
                  @output.makePositionVisible @output.length-1

                  @cmd.enabled = true
                  @cmd.backColor = FXColor::White
                  @cmd.text = ''
                  @cmd.setFocus
                end

              end

            end
          }
        end

      end
    end
  end
end
