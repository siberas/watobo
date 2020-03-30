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

       # def onBtnQuickScan(sender, sel, item)
        def run

        end


        def initialize()

          super()

          @settings = Watobo::Plugin::Sequencer::Settings

          @results = []

          @settings.export_path ||= Watobo.workspace_path

          @agent = Watobo::Plugin::Sequencer::Agent.new

          @sequence_name_dt = FXDataTarget.new('')

          @sequence = nil

          begin


            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            top_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)


            @sequence_name_txt = FXTextField.new(top_frame, 25,
                                               :target => @sequence_name_dt, :selector => FXDataTarget::ID_VALUE,
                                               :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            @create_btn = FXButton.new(top_frame, "create")
            @create_btn.disable
            @create_btn.connect(SEL_COMMAND) do
              puts "+ creating new sequence: #{@sequence_name_dt.value}"
              @sequence = Watobo::Sequence.new({ name: @sequence_name_dt.value.to_s })
            end

            @sequence_name_dt.connect(SEL_CHANGED) do
              puts "+ new sequence name: #{@sequence_name_dt.value}"
              if @sequence_name_dt.value.to_s.length > 4
                @create_btn.enable
              end
            end

            @load_btn = FXButton.new(top_frame, "load")
            @load_btn.connect(SEL_COMMAND) {  }

            splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)


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

            @save_btn = FXButton.new(@list_frame, "export", :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
            @save_btn.connect(SEL_COMMAND) { save_results }
          rescue => bang
            puts bang
            puts bang.backtrace
            exit
          end

        end

        private

        def create_chats
          chats = []
          @targets_frame.targets.each do |t|
            trequest = Watobo::Request.new(t)
            chats << @agent.do_request(trequest) if Watobo::HTTPSocket.siteAlive?(trequest)
          end
          chats

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