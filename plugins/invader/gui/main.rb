# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Invader
      include Watobo::Config

      MODE_SNIPER = 0x01
      MODE_PARAM = 0x00

      class Gui < Watobo::PluginGui

        window_title "Invader"
        icon_file "invader.ico"

        def initialize(chat = nil)

          super(:opts => DECOR_ALL, :width => 1000, :height => 600)

          @chat = chat

          begin


            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

            launch_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
            @launch_btn = FXButton.new(launch_frame, "LAUNCH")
            @pbar = FXProgressBar.new(launch_frame, nil, 0, LAYOUT_FILL_X | FRAME_SUNKEN | FRAME_THICK | PROGRESSBAR_HORIZONTAL)

            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)


            tabs_frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)


            @launch_btn.connect(SEL_COMMAND) {launch_invasion}

            @tabBook = FXTabBook.new(tabs_frame, nil, 0, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_RIGHT)

            FXTabItem.new(@tabBook, "Targets", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @target_frame = TargetFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN)
            @target_frame.set_request(@chat.request) if @chat.respond_to?(:request)
            @editor = @target_frame.editor

            FXTabItem.new(@tabBook, "Payloads", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            # frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
            @payload_frame = PayloadFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN)

            FXTabItem.new(@tabBook, "Settings", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @settings_frame = SettingsFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN)

            FXTabItem.new(@tabBook, "Samples", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @sample_frame = SamplesFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN)

            FXTabItem.new(@tabBook, "Stats", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN)


          rescue => bang
            puts bang
            puts bang.backtrace
            exit
          end

        end

        private

        def sniper_chats
          chatlist = []
          markers = @editor.matchPattern('%%[^%]*%%')
          markers.each do |pos, len|
            text = @editor.rawRequest
            # clear marks before, needs at least 5 chars for a valid mark
            pre_str = text[0..(pos - 1)]
            mark_str = text[pos..(pos + len - 1)]
            post_str = text[(pos + len)..-1]
            pre_str.gsub!(/%%([^%]*)%%/, "\\1")

            post_str.gsub!(/%%([^%]*)%%/, "\\1")

            req_text = pre_str + mark_str + post_str

            request = Watobo::Utils.text2request(req_text)
            chatlist << Watobo::Chat.new(request, [], :id => 0)

          end
          chatlist
        end


        def launch_invasion
          puts "INVAAAASIOOOOOOON"
          chatlist = []
          checklist = []


          sample_name = Time.now.strftime("%H:%M:%S")
          sample_set = SampleSet.new(sample_name)
          @sample_frame.add sample_set


          check = @target_frame.mode == MODE_SNIPER ? SniperCheck.new(Watobo.project) : Check.new(Watobo.project)

          check.set_payload_prefs @payload_frame.preferences
          check.set_payload_tweaks @payload_frame.tweaks

          check.subscribe(:new_check) do |source, chat|
            #puts "+ new sample for sample-set '#{sample_set.name}'"
            sample_set.add source, chat
          end
          checklist << check

          if @target_frame.mode == MODE_SNIPER
            chatlist = sniper_chats
          else
            request = @target_frame.get_request
            chatlist << Watobo::Chat.new(request, [], :id => 0)
          end


          scan_prefs = Watobo::Conf::Scanner.to_h
          scan_prefs[:scanlog_name] = @settings_frame.scanlog_name + '_' + Time.now.to_i.to_s
          scan_prefs[:update_contentlength] = true

          @scanner = Watobo::Scanner3.new(chatlist, checklist, Watobo::PassiveModules.to_a, scan_prefs)
          @pbar.total = @scanner.progress.values.inject(0) {|i, v| i += v[:total]}
          @pbar.progress = 0
          @pbar.barColor = 'red'

          @scanner.subscribe(:scan_finished) do

          end

          @scanner.run(:run_passive_checks => false)

          update_pbar

        end

        def update_pbar()
          @timer = update_timer(500) {
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

                remove_timer

              end
            end
          }
        end


      end
    end
  end
end