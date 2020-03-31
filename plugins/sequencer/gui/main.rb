# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      include Watobo::Settings

      class Gui < Watobo::PluginGui

        window_title "Sequencer"
        icon_file "sniper.ico"


        def start
          @results = []

        end

        def stop

        end


        def initialize()

          super()

          @config = Watobo::Plugin::Sequencer::Settings

          @results = []

          @config.last_path ||= Watobo.workspace_path

          @sequence_name_dt = FXDataTarget.new('')

          @sequence = nil

          @sender = Watobo::Plugin::Sequencer::Sender.new

          begin


            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

            top_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)


            @sequence_name_txt = FXTextField.new(top_frame, 25,
                                                 :target => @sequence_name_dt, :selector => FXDataTarget::ID_VALUE,
                                                 :opts => TEXTFIELD_NORMAL | LAYOUT_SIDE_RIGHT)

            @create_btn = FXButton.new(top_frame, "create")
            @create_btn.disable
            @create_btn.connect(SEL_COMMAND) do
              puts "+ creating new sequence: #{@sequence_name_dt.value}"
              @sequence = Watobo::Sequence.new({name: @sequence_name_dt.value.to_s})
            end

            @sequence_name_dt.connect(SEL_CHANGED) do
              puts "+ new sequence name: #{@sequence_name_dt.value}"
              if @sequence_name_dt.value.to_s.length > 4
                @create_btn.enable
              end
            end

            @load_btn = FXButton.new(top_frame, "load")
            @load_btn.connect(SEL_COMMAND) { load_sequence }

            @save_btn = FXButton.new(top_frame, "save", :opts => BUTTON_NORMAL)
            @save_btn.connect(SEL_COMMAND) { save_sequence }

            @log = FXCheckButton.new(top_frame, "log", nil, 0, JUSTIFY_LEFT | JUSTIFY_TOP | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)
            @log.checkState = true
            @sender.logging = true
            @log.connect(SEL_COMMAND) do
              @sender.logging = @log.checked? ? true : false
            end

            @run_btn = FXButton.new(top_frame, "run", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
            @run_btn.connect(SEL_COMMAND) { run_sequence }


            splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X | SPLITTER_HORIZONTAL | LAYOUT_FILL_Y | SPLITTER_TRACKING)


            @list_frame = ListFrame.new(splitter, :opts => LAYOUT_FILL_X)
            @list_frame.subscribe(:new_element) do |element|
              puts "+ add element to sequence"
              unless @sequence.nil?
                @sequence.add element
                @list_frame.update_elements @sequence
              else
                puts "!no sequence available!"
              end
            end

            @list_frame.subscribe(:send_element) do |element|
              @sender.do_request(element)
            end

            @list_frame.subscribe(:element_selected) { |element|
              @details_frame.element = element
            }

            @details_frame = DetailsFrame.new(splitter, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @details_frame.subscribe(:element_change) do
              @save_btn.textColor = 'red'
              @save_btn.enable
            end


          rescue => bang
            puts bang
            puts bang.backtrace
            exit
          end

        end

        private

        def save_sequence
          return false if @sequence.nil?

          filename = @sequence.file
          filename = FXFileDialog.getSaveFilename(self, "Select Sequence File", @config.last_path) if filename.nil?
          unless filename.empty?
            @config.last_path = File.dirname(filename)
            @config.save

            puts "+ saving sequence #{@sequence.name} to #{filename}" if $VERBOSE
            Thread.new(filename) { |fn|
              #    File.open(fn,"wb"){|fh| fh.print JSON.pretty_generate(@results) }
              File.open(fn, 'wb') { |f|
                f.print Marshal::dump(@sequence.to_h)
              }
            }
          end
        end

        def load_sequence
          filename = FXFileDialog.getOpenFilename(self, "Select Sequence File", @config.last_path)
          if filename != "" then
            @sequence = Watobo::Sequence.create filename
            @sequence_name_dt.value = @sequence.name
            @list_frame.update_elements @sequence
          end
        end

        def run_sequence
          @sender.run_sequence(@sequence)
        end


        def add_update_timer(ms)
          @timer = FXApp.instance.addTimeout(500, :repeat => true) {
            unless @scanner.nil?


              if @pbar.total > 0
                @pbar.progress = @scanner.sum_progress
              end

              if @scanner.finished?
                @scanner = nil
                # logger("Scan Finished!")
                @pbar.progress = 0
                @pbar.total = 0
                @pbar.barColor = 'grey' #FXRGB(255,0,0)
                FXApp.instance.removeTimeout(@timer)

                @result_frame.update

              end
            end
          }
        end


      end
    end
  end
end