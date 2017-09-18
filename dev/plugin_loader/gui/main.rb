# @private
module Watobo #:nodoc: all
  module Gui
    @application = FXApp.new('Watobo', 'Plugin Loader')

    def self.application
      @application
    end

    class PluginLoader < FXMainWindow

      def initialize()

        super(Watobo::Gui.application, "Plugin Tester", :width => 800, :height => 600)
        frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        button = FXButton.new(frame, "Open Plugin", :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT, :padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)

        button.connect(SEL_COMMAND) {
          dlg = Watobo::Plugin::JWT::Gui.new
          if dlg.execute != 0
            puts dlg.to_h.to_yaml
          end
        }
      end

      # Create and show the main window
      def create
        super # Create the windows
        show(PLACEMENT_SCREEN) # Make the main window appear

      end
    end


  end
end
