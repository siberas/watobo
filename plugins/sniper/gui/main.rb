# @private
module Watobo#:nodoc: all
  module Plugin
    class Sniper
      include Watobo::Settings

      class Gui < Watobo::PluginGui

        window_title "Sniper"
        icon_file "hunter.ico"



        def start
          @results = []
          @tree_view.clear
          @tree_view.set_base_dir @url.text
          Watobo::Plugin::CQ5.reset
         # Watobo::Plugin::CQ5.use_relative_path = @relative_path_cb.checked?
          Watobo::Plugin::CQ5.ignore_patterns = @ignore_cb.checked? ? @ignore_patterns_list.to_a : []
          Watobo::Plugin::CQ5.run( @url.text , @results_queue)
        end

        def stop
          Watobo::Plugin::CQ5.stop
        end

        def initialize()
          @results = []
          @export_path = Watobo.workspace_path
          @results_queue = Queue.new

          super()

          self.extend Watobo::Settings

          main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          
          url_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
         

          @start_btn = FXButton.new(url_frame, "start")

          @url.connect(SEL_COMMAND){ start }
          @start_btn.connect(SEL_COMMAND){ start }

          @stop_btn = FXButton.new(url_frame, "stop")
          @stop_btn.connect(SEL_COMMAND){ stop }
          
          splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
          targets_frame  = TargetsFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_WIDTH, :width => 450)
         
          

          top_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN,:height => 500)
          checks_frame  = FXVerticalFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_WIDTH, :width => 450)
          
         
          frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)

          @save_btn = FXButton.new(frame, "export", :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
          @save_btn.connect(SEL_COMMAND){ save_results }

        end





      end
    end
  end
end