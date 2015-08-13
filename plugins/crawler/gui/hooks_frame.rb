# @private 
module Watobo#:nodoc: all
  module Plugin
    module Crawler
      class Gui
        class HooksFrame < FXVerticalFrame
          
          def to_h
            hooks = {}
            pch = pre_conn_hook
            hooks[:pre_connect_hook] = pch if pch.respond_to? :call
            
            hooks
          end
          def pre_conn_hook
            return nil unless pre_conn_valid?
            hook = eval(pre_conn_code)
           
            hook
          end
          
          def selected
            @pre_txt.setFocus()
          end

          def pre_conn_valid?
            return false if pre_conn_code.empty?
            begin
              eval(pre_conn_code)
              return true
            rescue SyntaxError, LocalJumpError, NameError => e
            #  puts "Error in PreConnCode!!"
            #  puts e
            #  puts e.backtrace
              raise SyntaxError, "SyntaxError in Pre-Connect-Code'#{expr}'"
              #return false
            rescue => bang
              puts bang
              puts bang.backtrace
             return false
            #raise bang
            end

          end

          def pre_conn_code
            return "" if @pre_txt.text.empty?
            code = "lambda { |agent,request|\n"
            code << @pre_txt.text
            code << "\n}"
          end

          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|FRAME_THICK, :padding => 0)
            main = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y)

            gbframe = FXGroupBox.new(main, "Pre-Connection", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            #text_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding =>0)
            fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|TEXT_WORDWRAP)
            fxtext.backColor = fxtext.parent.backColor
            fxtext.disable
            text = "You can define a script which gets executed just before each connection. So you are able to modify the Mechanize::Agent and Mechanize::Requests just before the request is sent to the server.\n"
            text << "For more information about pre_connection_hooks check the Mechanize homepage (http://mechanize.rubyforge.org/)."

            fxtext.setText(text)

            FXLabel.new(frame, "lambda{ |agent, request|")
            txt_frame = FXVerticalFrame.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @pre_txt = FXText.new(txt_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
            FXLabel.new(frame, "}")
            @pre_txt.setText("")
            # cannot set the focus here because of a crash on ubuntu systems
            # https://bugs.launchpad.net/ubuntu/+source/fox1.6/+bug/887038
            #  @pre_txt.setFocus()
          end

        end
      end
    end
  end
end