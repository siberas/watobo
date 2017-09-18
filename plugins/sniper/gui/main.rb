# @private
module Watobo #:nodoc: all
  module Plugin
    class Sniper
      include Watobo::Settings

      class Gui < Watobo::PluginGui

        window_title "Sniper"
        icon_file "sniper.ico"


        def start
          @results = []
          @tree_view.clear
          @tree_view.set_base_dir @url.text

        end

        def stop

        end

       # def onBtnQuickScan(sender, sel, item)
        def start_scan
          log_message = "STARTING SNIPER SCAN"
#          quick_scan_options = dlg.options

          scan_chats = create_chats
          selected_checks = @policy_frame.getSelectedModules

          unless scan_chats.empty? then

            scan_prefs = Watobo::Conf::Scanner.to_h
            # we don't want logout detection during a QuickScan
            # TODO: let this decide the user!
            #scan_prefs[:logout_signatures] = [] if quick_scan_options[:detect_logout] == false
            #  scan_prefs[:csrf_requests] = @project.getCSRFRequests(@original_request) if quick_scan_options[:update_csrf_tokens] == true
            scan_prefs[:run_passive_checks] = false

            # logging required ?

            #if quick_scan_options[:enable_logging] and quick_scan_options[:scanlog_name]
            #  scan_prefs[:scanlog_name] = quick_scan_options[:scanlog_name]
            #end

 #           scan_prefs.update quick_scan_options

            if $DEBUG
              puts "* creating scanner ..."
              puts quick_scan_options.to_yaml
              puts "- - - - - - - - -"
              puts scan_prefs.to_yaml
            end

            # we only can have one thread for csrf_token updates ... because it's not thread-safe ... yet
            scan_prefs[:max_parallel_checks] = 1 if scan_prefs[:update_csrf_tokens] == true

            @scanner = Watobo::Scanner3.new(scan_chats, selected_checks, [], scan_prefs)

            sum_totals = 0
            @scanner.progress.each_value do |v|
              sum_totals += v[:total]
            end

            @pbar.total = sum_totals
            @pbar.progress = 0
            @pbar.barColor = 'red'

            csrf_requests = []

           # if quick_scan_options[:update_csrf_tokens] == true
           #   unless csrf_requests.empty?
           #     csrf_requests = Watobo::OTTCache.requests(req)
           #   end
           # end

            run_prefs = {
              #  :update_sids => @updateSID.checked?,
              #  :update_session => @updateSession.checked?,
                :csrf_requests => csrf_requests,
                :csrf_patterns => scan_prefs[:csrf_patterns],
                :www_auth => scan_prefs[:www_auth],
                #:follow_redirect => quick_scan_options[:follow_redirect],
            }

            #logger("Scan Started ...")
            Watobo.log(log_message, :sender => self.class.to_s.gsub(/.*:/, ""))

            #@scan_status = :SCANNER_STARTED

            add_update_timer(500)
            @scanner.run(run_prefs)

          end
        end


        def initialize()

          super()

          @settings = Watobo::Plugin::Sniper::Settings

          @results = []

          @settings.export_path ||= Watobo.workspace_path

          @agent = Watobo::Plugin::Sniper::Agent.new


          begin


            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            url_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)


            @start_btn = FXButton.new(url_frame, "start")

            @start_btn.connect(SEL_COMMAND) { start_scan }

            @stop_btn = FXButton.new(url_frame, "stop")
            @stop_btn.connect(SEL_COMMAND) { stop }

            splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
            @targets_frame = TargetsFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)
            @policy_frame = ChecksPolicyFrame.new(splitter)

            @policy_frame.subscribe(:sel_command) {
              puts '* checks changed'
            }
            @result_frame = ResultFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X)


            #top_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN,:height => 500)
            #checks_frame  = FXVerticalFrame.new(splitter, :opts => LAYOUT_SIDE_BOTTOM, :width => 450)
            @pbar = FXProgressBar.new(main_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)

            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)


            frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)

            @save_btn = FXButton.new(frame, "export", :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
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