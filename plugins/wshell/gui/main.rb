# @private 
module Watobo#:nodoc: all
  module Plugin
    class WShell
      class Gui < Watobo::PluginGui

        window_title "WATOBO Shell (experimental)"
        icon_file "wsh.ico"
        def initialize()
          super()

          @history_pos = 0
          
           hs_green = FXHiliteStyle.new
       # hs_green.normalForeColor = FXRGBA(255,255,255,255) 
       # hs_green.normalForeColor = FXRGBA(0,255,0,1)   
        #hs_green.normalBackColor = FXRGBA(0,255,0,1)   
        hs_green.style = FXText::STYLE_BOLD
        
        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,0,0,1) 
        #hs_red.normalBackColor = FXRGBA(255,0,0,1)   
        hs_red.style = FXText::STYLE_BOLD
          
          frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          output_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
          @output = FXText.new(output_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @output.editable = false
          @output.styled = true
          #@font = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD)
          @output.setFont(FXFont.new(getApp(), "courier", 10,  FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
            @output.hiliteStyles = [ hs_red, hs_green]

          @output.appendStyledText Watobo::Plugin::WShell::HELP_TEXT, 2

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
              @history_pos += 1 if @history_pos < Watobo::Plugin::WShell.history_length-1
              set_history_cmd
            fin = true
            end
            fin
          end

          @cmd.setFocus()
          @cmd.setDefault()

          @cmd_btn = FXButton.new(cmd_frame, "run")
          @executions = Watobo::Plugin::WShell.executions

          @cmd_btn.connect(SEL_COMMAND){ run_cmd }

          update_timer{
            unless @executions.empty?
              cmd, result = @executions.pop

             # @output.appendText(">> #{cmd}\n")
              @output.appendText("#{result}\n")
              @output.appendText("\n---\n")

              @output.makePositionVisible @output.length-1

              @cmd.enabled = true
              @cmd.backColor = FXColor::White
              @cmd.text = ''
            @cmd.setFocus

            end
          }
        end

        private

        def set_history_cmd()
          cmd = Watobo::Plugin::WShell.history_at @history_pos
          @cmd.text = cmd
        end

        def run_cmd
          unless @cmd.text.empty?
            if @cmd.text =~ /^help$/i
            #  @output.appendText(Watobo::Plugin::WShell.help)
            @output.appendStyledText Watobo::Plugin::WShell::HELP_TEXT, 2
              @cmd.text = ''
            return true
            end
            @output.appendStyledText ">> #{@cmd.text}\n", 1
            @history_pos = Watobo::Plugin::WShell.history_length+1
            @cmd.enabled = false
            @cmd.backColor = @cmd.parent.backColor

            Watobo::Plugin::WShell.execute_cmd @cmd.text
          end
        end
      end
    end
  end
end