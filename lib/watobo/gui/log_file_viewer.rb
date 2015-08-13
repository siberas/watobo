# @private 
module Watobo#:nodoc: all
  module Gui
    class LogFileViewer < FXVerticalFrame

      include Watobo::Constants
      def show_logs
        begin
           @textbox.setText(Watobo.logs)
        rescue => bang
          puts "! Could not show logs"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

   
      def initialize(parent, mode = nil, opts)
        opts[:padding]=0
        
        super(parent, opts)

        update_btn = FXButton.new(self, "Update",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT).connect(SEL_COMMAND){ show_logs }
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
        @textbox = FXText.new(frame,  nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_AUTOSCROLL|TEXT_READONLY)
        @textbox.editable = false
      show_logs  
   
      end
      
          end

  end
end