inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'watobo'
require 'fox16'

include Fox

# @private
module Watobo #:nodoc: all
  module Gui
    @application = FXApp.new('Watobo', 'Plugin Loader')

    def self.application
      @application
    end

    %w( load_icons gui_utils load_plugins session_history save_default_settings master_password session_history save_project_settings save_proxy_settings ).each do |l|
      f = File.join("watobo", "gui", "utils", l)
      puts ">> Loading #{f}"
      require f

    end

    require 'watobo/gui/utils/init_icons'
    puts 'loading mixins'
    require 'watobo/gui/mixins/events'
    require 'watobo/gui/mixins/gui_settings'

    gui_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "lib", "watobo", "gui"))

    Dir.glob("#{gui_path}/*.rb").each do |cf|
      next if File.basename(cf) == 'main_window.rb' # skip main_window here, because it must be loaded last
      f = File.join("watobo", "gui", File.basename(cf))
      puts "Loading >> #{f}"
      require f
    end

    puts "Loading plugin templates ..."
    require 'watobo/gui/templates/plugin'
    require 'watobo/gui/templates/plugin2'
    require 'watobo/gui/templates/plugin_base'


    require File.join(Watobo.plugin_path, 'jwt', 'jwt')


    class MainGui < FXMainWindow

      def initialize(app)
# Call base class initializer first
        super(app, "Plugin Tester", :width => 800, :height => 600)
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

    MainGui.new(@application)
    @application.create
    @application.run
  end
end