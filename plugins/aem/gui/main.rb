# @private
module Watobo#:nodoc: all
  module Plugin
    class AEM
      class Gui < Watobo::PluginGui

        window_title "Adobe Experience Manager Enumerator"
        icon_file "aem.ico"
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

          main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          
          url_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
          @url = FXTextField.new(url_frame, 25, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_LEFT)

          @url.setFocus()
          @url.setDefault()

          @start_btn = FXButton.new(url_frame, "start")

          @url.connect(SEL_COMMAND){ start }
          @start_btn.connect(SEL_COMMAND){ start }

          @stop_btn = FXButton.new(url_frame, "stop")
          @stop_btn.connect(SEL_COMMAND){ stop }
          
          splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
          opts_frame  = FXVerticalFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_WIDTH, :width => 450)
         
          
          gbframe = FXGroupBox.new(opts_frame, "Ignore Path Patterns", FRAME_GROOVE|LAYOUT_FILL_Y, 0, 0, 0, 0)
            iframe = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @ignore_cb = FXCheckButton.new(iframe, "enable", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @ignore_cb.checkState = true

            @invert_cb = FXCheckButton.new(iframe, "invert", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @invert_cb.checkState = false
            @invert_cb.disable
            
            FXLabel.new(iframe, "Ignore if url matches one of the following patterns (regex):")
            @ignore_patterns_list = Watobo::Gui::ListBox.new(iframe)
            @ignore_patterns_list.set %w( replication\/data jcr.*versionstorage workflow\/instances audit\/com.day.cq.replication\/content )
          #@scope_only_cb.connect(SEL_COMMAND) {  }

          #mr_splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_HORIZONTAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
          # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
          top_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN,:height => 500)
          @tree_view = TreeView.new top_frame
          
         
          frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
          @counter = FXLabel.new(frame, "")
          @queue_size = FXLabel.new(frame, "")
          update_counter

          @tree_view.subscribe(:show_info){|item|
            puts "Item clicked"
            puts item[:url]
          }

          @save_btn = FXButton.new(frame, "save", :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
          @save_btn.connect(SEL_COMMAND){ save_results }

          update_timer(500){            
            max = 100
            count = 0
            while @results_queue.size > 0 and count < max
              r = @results_queue.deq
              @results << r
              #puts @results.length
              @tree_view.add r
              count += 1
            end            
            update_counter 
          }
        end

        private

        def update_counter
          @counter.text = "Total: #{@results.length}"
          @queue_size.text = "Queue: #{Watobo::Plugin::CQ5.queue_size}"
        end

        def save_results
          fname = "cq5_" + Time.now.to_i.to_s + ".json"
          dst_file = File.join(@export_path, fname)
          filename = FXFileDialog.getSaveFilename(self, "Select Export File", dst_file)
          if filename != "" then
            @export_path = File.dirname filename
            Thread.new(filename){|fn|
              File.open(fn,"wb"){|fh| fh.print JSON.pretty_generate(@results) }
            }
          end
        end

      end
    end
  end
end