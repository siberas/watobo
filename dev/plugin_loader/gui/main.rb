# @private
module Watobo #:nodoc: all
  module Gui
    @application = FXApp.new('Watobo', 'Plugin Loader')

    def self.application
      @application
    end

    class PluginLoader < FXMainWindow

      def initialize(filter)

        super(Watobo::Gui.application, "Plugin Tester", :width => 800, :height => 600)

        # load all plugins
        Watobo::Gui::Utils.load_plugins("DUMMY", filter)
        @frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE)
        @plugin_board = Watobo::Gui::PluginBoard.new(@frame)

      end


      # Create and show the main window
      def create
        super # Create the windows

        show(PLACEMENT_SCREEN) # Make the main window appear

        @plugin_board.updateBoard

      end
    end


  end
end
