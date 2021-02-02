# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Filescanner

      include Watobo::Config
      #include Watobo::Plugin

      class Gui < Watobo::PluginGui
        window_title "File Scanner"
        icon_file "filescanner.ico"

        include Watobo::Subscriber

        attr_accessor :config

        def initialize(chat = nil)
          #super(owner, "File Finder", project, :opts => DECOR_ALL, :width => 800, :height => 600)
          super(:opts => DECOR_ALL, :width => 1000, :height => 600, :padding => 0)

          @scanner = nil
          #self.extend Watobo::Subscriber
          @config = Watobo::Plugin::Filescanner.config
          main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @status_frame = Filescanner::Gui::StatusFrame.new(self, main_frame, :opts => LAYOUT_FILL_X)
          @status_frame.subscribe(:start){ start_scan }
          mr_splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_HORIZONTAL|SPLITTER_REVERSED|SPLITTER_TRACKING)

          @settings_frame = Filescanner::Gui::SettingsFrame.new(self, mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @settings_frame.subscribe(:site_changed){|site|}

          @request_frame = Filescanner::Gui::RequestFrame.new(self, mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @request_frame.subscribe(:armed){ @status_frame.armed }

        end

        def start_scan
          puts @settings_frame.settings
          @scanner = Watobo::Plugin::Filescanner.new( @request_frame.request, @settings_frame.settings )
          puts @scanner.status

          @scanner.run()
          start_update_timer
          puts @scanner.status
        end

        private

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


if __FILE__ == $0
  puts "Running #{__FILE__}"
  catalog = Watobo::Plugin::Catalog.new(project)
end
