# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Nuclei

      include Watobo::Config

      class Gui < Watobo::PluginGui
        window_title "Nuclei Scanner (experimental)"
        icon_file "nuclei.ico"

        include Watobo::Subscriber

        attr_accessor :config

        def initialize(chat = nil)
          #super(owner, "File Finder", project, :opts => DECOR_ALL, :width => 800, :height => 600)
          super(:opts => DECOR_ALL, :width => 1000, :height => 650, :padding => 0)
          @config = Watobo::Plugin::Nuclei.config

          @config.load

          @status_frame = Nuclei::Gui::StatusFrame.new(self, :opts => LAYOUT_FILL_X)
          @status_frame.subscribe(:on_start_btn) { start_scan }
          @status_frame.subscribe(:on_cancel_btn) { stop_scan }
          @status_frame.disarmed!

          # frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @tabBook = FXTabBook.new(self, nil, 0, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_RIGHT)
          tab = FXTabItem.new(@tabBook, "Templates", nil)
          frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)

          @mr_splitter = FXSplitter.new(frame, LAYOUT_FILL_X | LAYOUT_FILL_Y | SPLITTER_HORIZONTAL | SPLITTER_REVERSED | SPLITTER_TRACKING)
          @tree_list_frame = TreeListFrame.new(@mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          # subscribe to changes inside tree
          # - update infos, button etc.
          @tree_list_frame.subscribe(:sel_changed) do
            update_status_frame
          end

          @tree_list_frame.subscribe(:item_selected) do |item|
            @info_frame.update_item item
          end

          @tree_list_frame.subscribe(:new_template_dir) do |f|
            init_templates(f)
          end

          @info_frame = TemplateInfoFrame.new(@mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

          tab = FXTabItem.new(@tabBook, "Request", nil)
          @request_frame = RequestFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
          @request_frame.subscribe(:sel_changed) do
            # check if request settings are ok
            update_status_frame
          end

          tab = FXTabItem.new(@tabBook, "Options", nil)
          # @request_frame = RequestFrame.new(tab, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @options_frame = OptionsFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)

        end

        def create
          super # Create the windows

          show(PLACEMENT_SCREEN) # Make the main window appear

          unless @config.template_dir.empty?
            if init_templates(@config.template_dir)
              update_status_frame
            end
          end

          size = @status_frame.width / 2
          # puts "set splitter to size #{size}"
          @mr_splitter.setSplit 1, size
        end

        private

        def start_scan
          #  puts @settings_frame.settings
          @scanner = Watobo::Plugin::NucleiScanner.new(@request_frame.request, @tree_list_frame.getCheckedData, @options_frame.to_h)
          #puts @scanner.status

          @scanner.run(@options_frame.to_h)
          start_update_timer
          #puts @scanner.status
        end

        def update_status_frame
          if request_ready? && template_selected?
            @status_frame.armed!
          end
        end

        def request_ready?
          r = @request_frame.request
          r.host.length > 0 && r.headers.length > 0
        end

        def template_selected?
          @tree_list_frame.getCheckedData.length > 0
        end

        def init_templates(template_dir)
          return false unless File.exist? template_dir
          @templates = []
          Dir.glob("#{template_dir}/*").each do |dir|
            next if dir == 'helpers' # skip helpers directory
            Dir.glob("#{dir}/**/*.yaml").each do |tf|
              fs = tf.gsub(/^#{template_dir}\//, '').split('/')
              fs.pop # remove file part
              data = Watobo::Plugin::NucleiScanner::NucleiCheck.new(self.object_id, tf, template_dir: template_dir)
              fs.push data.info[:check_name]

              template = {
                  :name => fs.join('|'),
                  :enabled => false,
                  :data => data
              }
              @templates << template
            end
          end
          @tree_list_frame.elements = @templates
          true
        end

        def start_update_timer
          interval = 2000
          @_prev_progress = 0
          @timer = FXApp.instance.addTimeout(interval, :repeat => true) {
            unless @scanner.nil?
              progress = @scanner.sum_progress

              speed = progress - @_prev_progress
              @status_frame.update_progress(progress, @scanner.sum_total, speed)

              if @scanner.finished?
                FXApp.instance.removeTimeout(@timer)
                msg = "Scan Finished!"
                #   @log_viewer.log(LOG_INFO, msg)
                Watobo.log(msg, :sender => "Catalog")
                @scanner = nil

              end
            end
          }


        end

      end
    end
  end
end
