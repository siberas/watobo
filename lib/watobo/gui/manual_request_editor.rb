# @private 
module Watobo #:nodoc: all
  module Gui

    class HistoryItem

      attr :raw_request

      def request
        @chat.request
      end

      def response
        @chat.response
      end

      def initialize(chat, raw_request)
        @chat = chat
        @raw_request = raw_request
      end
    end

    class ManualRequestSender < Watobo::Session
      def initialize(session_id)

        super(session_id, Watobo::Conf::Scanner.to_h)

      end

      def sendRequest(new_request, prefs)

        if prefs[:run_login] == true
          login_chats = Watobo::Conf::Scanner.login_chat_ids.uniq.map { |id| Watobo::Chats.get_by_id(id) }
          #  puts "running #{login_chats.length} login requests"
          #  puts login_chats.first.class
          runLogin(login_chats, prefs)
        end

        request = Watobo::Request.new(new_request)
        begin
          test_req, test_resp = self.doRequest(request, prefs)
          #rq = Watobo::Request.new test_req
          # rs = Watobo::Response.new test_resp
          #rs.unchunk
          #rs.unzip
          return test_req, test_resp
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil, nil
      end
    end

    #
    #--------------------------------------------------------------------------------------------
    #
    class ManualRequestEditor < FXDialogBox

      include Watobo::Constants
      include Watobo::Gui::Icons

      # include Responder
      # ID_CTRL_S = ID_LAST
      # ID_LAST = ID_CTRL_S + 1
      SCANNER_IDLE = 0x00
      SCANNER_STARTED = 0x01
      SCANNER_FINISHED = 0x02
      SCANNER_CANCELED = 0x04

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def openCSRFTokenDialog(sender, sel, item)
        csrf_dlg = CSRFTokenDialog.new(self, @chat)
        if csrf_dlg.execute != 0 then
          csrf_ids = csrf_dlg.getTokenScriptIds()
          Watobo::OTTCache.set_chat_ids @chat, csrf_ids
          Watobo::Conf::OttCache.patterns = csrf_dlg.getTokenPatterns()
          Watobo::Conf::OttCache.save_project
        end
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def onRequestReset(sender, sel, item)
        @req_builder.setRequest(@original_request)
      end

      def logger(message)
        @log_viewer.log(LOG_INFO, message)
        puts "[#{self.class.to_s}] #{message}" if $DEBUG
      end

      def addHistoryItem(chat, raw_request)
        @history.push HistoryItem.new(chat, eval(YAML.load(YAML.dump(raw_request.inspect))))

        @history.shift if @history.length > @history_size

        @diff_frame.updateHistory(@history)
      end

      def onBtnQuickScan(sender, sel, item)
        dlg = Watobo::Gui::QuickScanDialog.new(self, :target_chat => @chat, :enable_one_time_tokens => @updateCSRF.checked?)
        scan_chats = []
        if sender.text =~ /Cancel/i
          @scanner.cancel() if @scanner.respond_to? :cancel
          @scanner = nil
          logger("QuickScan canceled by user")
          @pbar.progress = 0
          @pbar.total = 0
          @pbar.barColor = 'grey' #FXRGB(255,0,0)
          sender.text = "QuickScan"
          return
        end

        if dlg.execute != 0 then
          scan_modules = []
          sender.text = "Cancel"
          quick_scan_options = dlg.options
          # puts quick_scan_options.to_yaml

          if quick_scan_options[:use_orig_request] == true then
            req = @original_request
          else
            req = @req_builder.parseRequest()
          end

          scan_chats.push Chat.new(Watobo::Request.new(req), Watobo::Response.new(@chat.response), :id => @chat.id, :run_passive_checks => false)
        end

        unless scan_chats.empty? then

          log_message = ["QuickScan Started"]
          log_message << "Target URL: #{scan_chats.first.request.url}"

          acc = dlg.selectedModules

          acc.each do |ac|
            log_message << "Module: #{ac.check_name}"
          end

          # scan_prefs = @project.getScanPreferences
          scan_prefs = Watobo::Conf::Scanner.to_h
          # we don't want logout detection during a QuickScan
          # TODO: let this decide the user!
          scan_prefs[:logout_signatures] = [] if quick_scan_options[:detect_logout] == false
          #  scan_prefs[:csrf_requests] = @project.getCSRFRequests(@original_request) if quick_scan_options[:update_csrf_tokens] == true
          scan_prefs[:run_passive_checks] = false

          # logging required ?

          if quick_scan_options[:enable_logging] and quick_scan_options[:scanlog_name]
            scan_prefs[:scanlog_name] = quick_scan_options[:scanlog_name]
          end

          scan_prefs.update quick_scan_options

          if $DEBUG
            puts "* creating scanner ..."
            puts quick_scan_options.to_yaml
            puts "- - - - - - - - -"
            puts scan_prefs.to_yaml
          end

          # we only can have one thread for csrf_token updates ... because it's not thread-safe ... yet
          scan_prefs[:max_parallel_checks] = 1 if scan_prefs[:update_csrf_tokens] == true

          @scanner = Watobo::Scanner3.new(scan_chats, acc, [], scan_prefs)

          sum_totals = 0
          @scanner.progress.each_value do |v|
            sum_totals += v[:total]
          end
          @pbar.total = sum_totals
          @pbar.progress = 0
          @pbar.barColor = FXRGB(255, 0, 0)

          csrf_requests = []

          if quick_scan_options[:update_csrf_tokens] == true
            unless csrf_requests.empty?
              csrf_requests = Watobo::OTTCache.requests(req)
              # else
              #  puts "* No CSRF requests defined for request:"
              #  puts req
              #  puts "---"
            end
          end

          run_prefs = {
              :update_sids => @updateSID.checked?,
              :update_session => @updateSession.checked?,
              :csrf_requests => csrf_requests,
              :csrf_patterns => scan_prefs[:csrf_patterns],
              :www_auth => scan_prefs[:www_auth],
              :follow_redirect => quick_scan_options[:follow_redirect],
          }

          logger("Scan Started ...")
          Watobo.log(log_message, :sender => self.class.to_s.gsub(/.*:/, ""))

          @scan_status = SCANNER_STARTED
          @scanner.run(run_prefs)

        end

        # return 0

      end

      def onBtnSendClick(sender, sel, item)
        sendManualRequest()
      end

      def onPreviewClick(sender, sel, item)
        @request_viewer.setText('')
        new_request = @req_builder.parseRequest
        #  puts "new request: #{new_request}"
        @request_viewer.setText(new_request)
        @tabBook.current = 1
      end

      def showHistory(dist=0, pos=nil)
        if @history.length > 0

          current_pos = @history_pos_dt.value
          new_pos = current_pos + dist
          new_pos = 1 if new_pos <= 0
          new_pos = @history.length if new_pos > @history.length

          @req_builder.setRequest(@history[new_pos-1].raw_request)
          @req_builder.highlight("(%%[^%]*%%)")

          @response_viewer.setText(@history[new_pos-1].response)

          @history_pos_dt.value = new_pos
          @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          return new_pos
        end
        return 0 if dist == 0 and not pos
      end

      def add_handler
        @handler_path ||= Watobo.working_directory + '/'
        handler_filename = FXFileDialog.getOpenFilename(self, "Select handler file", @handler_path, "*.rb\n*")
        if handler_filename != "" then
          if File.exist?(handler_filename) then
            @handler_file = handler_filename
            @handler_path = File.dirname(handler_filename) + "/"
            Watobo::EgressHandlers.add(handler_filename)
            update_egress
          end
        end

      end

      def update_egress
        @egress_handlers.clearItems
        @egress.disable
        @egress_handlers.disable
        if Watobo::EgressHandlers.length > 0
          @egress.enable
          @egress_handlers.enable
          #@egress_btn.enable
          Watobo::EgressHandlers.list { |h|
            @egress_handlers.appendItem(h.to_s, nil)
          }
        end
      end

      def initialize(owner, project, chat)
        begin
          # Invoke base class initialize function first

          super(owner, "Manual Request Toolkit", :opts => DECOR_ALL, :width => 850, :height => 600)

          @event_dispatcher_listeners = Hash.new
          @chat_queue = Queue.new

          @request_sender = ManualRequestSender.new(self.object_id)
          @request_sender.subscribe(:follow_redirect) { |loc| logger("follow redirect -> #{loc}") }
          @responseFilter = FXDataTarget.new("")

          @chat = chat

          if chat.respond_to? :request
            self.title = "#{chat.request.method} #{chat.request.url}"
          end

          @original_request = chat.copyRequest

          @project = project

          @csrf_requests = []

          @tselect = ""
          @sel_pos = ""
          @sel_len = ""

          @last_request = nil
          @last_response = nil

          @history_size = 10
          @history = []
          @counter = 0

          @scanner = nil

          @new_response = nil
          @new_request = nil

          @update_lock = Mutex.new
          @scan_status_lock = Mutex.new
          @scan_status = SCANNER_IDLE


          self.icon = ICON_MANUAL_REQUEST

          # Construct some hilite styles
          hs_red = FXHiliteStyle.new
          hs_red.normalForeColor = FXRGBA(255, 255, 255, 255) # FXColor::Red
          hs_red.normalBackColor = FXRGBA(255, 0, 0, 1) # FXColor::White
          hs_red.style = FXText::STYLE_BOLD

          mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
          # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
          top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM, :height => 500)
          top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)

          log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :height => 100)

          #LAYOUT_FILL_X in combination with LAYOUT_FIX_WIDTH

          req_editor = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|FRAME_GROOVE, :width => 400, :height => 500)

          req_edit_header = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X)

          @req_builder = RequestBuilder.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
          @req_builder.subscribe(:hotkey_ctrl_s) {
            simulatePressSendBtn()
            sendManualRequest()
          }
          @req_builder.subscribe(:hotkey_ctrl_enter) {
            simulatePressSendBtn()
            sendManualRequest()
          }

          @req_builder.subscribe(:error) { |msg| logger(msg) }

          @req_builder.setRequest(@original_request)

          history_navigation = FXHorizontalFrame.new(req_edit_header, :opts => FRAME_NONE)
          FXLabel.new(history_navigation, "History:", :opts => LAYOUT_CENTER_Y)
          hback = FXButton.new(history_navigation, "<", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          @history_pos_dt = FXDataTarget.new(0)
          @history_pos = FXTextField.new(history_navigation, 2, @history_pos_dt, FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|FRAME_GROOVE|FRAME_SUNKEN)
          @history_pos.justify = JUSTIFY_RIGHT
          @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)

          hback.connect(SEL_COMMAND) { showHistory(-1) }
          hnext = FXButton.new(history_navigation, ">", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          hnext.connect(SEL_COMMAND) { showHistory(1) }

          menu = FXMenuPane.new(self)
          FXMenuCommand.new(menu, "-> GET").connect(SEL_COMMAND, method(:trans2Get))
          FXMenuCommand.new(menu, "-> POST").connect(SEL_COMMAND, method(:trans2Post))
          #  FXMenuCommand.new(menu, "POST <=> GET").connect(SEL_COMMAND, method(:switchMethod))

          req_reset_button = FXButton.new(req_edit_header, "Reset", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_FILL_Y)
          req_reset_button.connect(SEL_COMMAND, method(:onRequestReset))

          # Button to pop menu
          FXMenuButton.new(req_edit_header, "&Transform", nil, menu, (MENUBUTTON_DOWN|FRAME_RAISED|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_RIGHT|LAYOUT_FILL_Y))

          frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :padding => 0)
          req_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          #eq_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)

          #opt = FXGroupBox.new(req_options, "Request Options", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)

          @settings_tab = FXTabBook.new(req_options, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

          resp_tab = FXTabItem.new(@settings_tab, "Request Options", nil)
          opt= FXVerticalFrame.new(@settings_tab, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          @updateContentLength = FXCheckButton.new(opt, "Update Content-Length", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @updateContentLength.checkState = true

          @followRedirect = FXCheckButton.new(opt, "Follow Redirects", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @followRedirect.checkState = false

          eframe = FXHorizontalFrame.new(opt, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
          @egress = FXCheckButton.new(eframe, "Egress", nil, 0, JUSTIFY_LEFT|JUSTIFY_CENTER_Y|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @egress.checkState = false


          @egress_handlers = FXComboBox.new(eframe, 5, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP)
          #@filterCombo.width =200

          @egress_handlers.numVisible = 0
          @egress_handlers.numColumns = 23
          @egress_handlers.editable = false
          @egress_handlers.connect(SEL_COMMAND) { |sender, sel, name|
            Watobo::EgressHandlers.last = name
          }

          # @egress_handlers.appendItem('none', nil)
          @egress_add_btn = FXButton.new(eframe, "add", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          @egress_add_btn.connect(SEL_COMMAND) { add_handler }
          #@egress_handlers.connect(SEL_COMMAND, method(:onRequestChanged))
          @egress_btn = FXButton.new(eframe, "reload", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          @egress_btn.connect(SEL_COMMAND) {
            Watobo::EgressHandlers.reload
            update_egress
          }

          update_egress

          i = @egress_handlers.findItem(Watobo::EgressHandlers.last)
          #puts "Last Item Index: #{i} (#{Watobo::EgressHandlers.last})"
          @egress_handlers.setCurrentItem(i) if i >= 0


          @logChat = FXCheckButton.new(opt, "Log Chat", nil, 0,
                                       ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @logChat.checkState = false

          sess_tab = FXTabItem.new(@settings_tab, "Session Settings", nil)
          session_frame = FXVerticalFrame.new(@settings_tab, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          sidframe = FXHorizontalFrame.new(session_frame, :opts => FRAME_NONE|LAYOUT_FILL_X|PACK_UNIFORM_HEIGHT, :padding => 0)
          @updateSID = FXCheckButton.new(sidframe, "Update SID Cache ...", nil, 0, JUSTIFY_LEFT|JUSTIFY_CENTER_Y|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @updateSID.checkState = false
          FXButton.new(sidframe, "Clear", nil, nil, 0, FRAME_RAISED|FRAME_THICK).connect(SEL_COMMAND) {
            Watobo::SIDCache.acquire(self.object_id).clear
          }

          @updateSession = FXCheckButton.new(session_frame, "Update Session", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @updateSession.checkState = true
          @updateSession.connect(SEL_COMMAND) do |sender, sel, item|
            @runLogin.enabled = @updateSession.checked?
          end

          @runLogin = FXCheckButton.new(session_frame, "Run Login", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @runLogin.checkState = false

          csrf_frame = FXHorizontalFrame.new(session_frame, :opts => LAYOUT_FILL_X|PACK_UNIFORM_HEIGHT, :padding => 0)
          @updateCSRF = FXCheckButton.new(csrf_frame, "Update One-Time-Tokens ...", nil, 0, JUSTIFY_LEFT|ICON_BEFORE_TEXT)
          @updateCSRF.checkState = false
          @csrf_settings_btn = FXButton.new(csrf_frame, "Settings", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          @csrf_settings_btn.connect(SEL_COMMAND, method(:openCSRFTokenDialog))

          #@updateCSRF.connect(SEL_COMMAND) do |sender, sel, item|
          #   if @updateCSRF.checked? then
          #      @csrf_settings_btn.enable
          #   else
          #      @csrf_settings_btn.disable
          #   end
          #end

          ##################################################

          button_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LAYOUT_RIGHT, :width => 100)
          send_frame = FXVerticalFrame.new(button_frame, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X, :padding => 2)
          send_frame.backColor = FXColor::Red
          #btn_send = FXButton.new(frame, "\nSEND", ICON_SEND_REQUEST, nil, 0, :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH|LAYOUT_RIGHT, :width => 100)
          @btn_send = FXButton.new(send_frame, "\nSEND", ICON_SEND_REQUEST, nil, 0, :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_Y|LAYOUT_FILL_X|LAYOUT_RIGHT)
          btn_prev = FXButton.new(button_frame, "preview >>", nil, nil, 0, :opts => LAYOUT_FILL_X|FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
          btn_prev.connect(SEL_COMMAND, method(:onPreviewClick))

          frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X|FRAME_GROOVE)

          @btn_quickscan = FXButton.new(frame, "QuickScan", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          @btn_quickscan.connect(SEL_COMMAND, method(:onBtnQuickScan))
          @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
          @pbar.progress = 0
          @pbar.total = 0
          @pbar.barColor = 'grey' #FXRGB(255,0,0)

          # TODO: Implement font sizing
          #@req_builder.font = FXFont.new(app, "courier" , 14, :encoding=>FONTENCODING_ISO_8859_1)

          result_viewer = FXVerticalFrame.new(top_splitter, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE|LAYOUT_FIX_WIDTH, :width => 400)

          # log_viewer = FXVerticalFrame.new(bottom_frame, :opts => LAYOUT_FILL_X|FRAME_GROOVE|LAYOUT_BOTTOM)

          @tabBook = FXTabBook.new(result_viewer, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

          resp_tab = FXTabItem.new(@tabBook, "Response", nil)
          frame = FXVerticalFrame.new(@tabBook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
          @response_viewer = Watobo::Gui::ResponseViewer.new(frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
          #@response_viewer.ma
          @response_viewer.max_len = 0

          options = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
          frame = FXHorizontalFrame.new(options, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
          frame.backColor = FXColor::White
          label = FXLabel.new(frame, "MD5: ", :opts => LAYOUT_FILL_Y|JUSTIFY_CENTER_Y)
          label.backColor = FXColor::White
          @responseMD5 = FXLabel.new(frame, "-N/A-", :opts => LAYOUT_FILL_Y|JUSTIFY_CENTER_Y)
          @responseMD5.backColor = FXColor::White

          browser_button = FXButton.new(options, "Browser-View", ICON_BROWSER_MEDIUM, nil, 0, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
          browser_button.connect(SEL_COMMAND) {
            begin
              unless @current_chat.nil?
                #@interface.openBrowser(@last_request, @last_response)
                notify(:show_browser_preview, @current_chat.request, @current_chat.response)
              end
            rescue => bang
              puts bang

            end
          }

          req_tab = FXTabItem.new(@tabBook, "Request", nil)
          @request_viewer = Watobo::Gui::RequestViewer.new(@tabBook, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)


          diff_tab = FXTabItem.new(@tabBook, "Differ", nil)

          @diff_frame = DiffFrame.new(@tabBook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

          log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
          @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          #--------------------------------------------------------------------------------

          @btn_send.connect(SEL_COMMAND, method(:onBtnSendClick))

          add_update_timer(250)

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end

      end

      private

      def add_update_timer(ms)
        Watobo.save_thread {
          unless @scanner.nil?
            @scan_status_lock.synchronize do

              if @pbar.total > 0
                @pbar.progress = @scanner.sum_progress
              end

              if @scanner.finished?
                @scanner = nil
                logger("Scan Finished!")
                @pbar.progress = 0
                @pbar.total = 0
                @pbar.barColor = 'grey' #FXRGB(255,0,0)
                @btn_quickscan.text = "QuickScan"
              end
            end
          end
        }
      end

      def sendManualRequest
        @request_viewer.setText('')
        @response_viewer.setText('')
        new_request = @req_builder.parseRequest

        if new_request.nil?
          logger("Could not send request!")
          return false
        end

        csrf_requests = []

        prefs = Watobo::Conf::Scanner.to_h

        egress_handler = @egress.checked? ? @egress_handlers.getItem(@egress_handlers.currentItem) : ''


        current_prefs = {:run_login => @updateSession.checked? ? @runLogin.checked? : false,
                         :update_session => @updateSession.checked?,
                         :update_contentlength => @updateContentLength.checked?,
                         :update_otts => @updateCSRF.checked?,
                         #   :csrf_requests => csrf_requests,
                         # :csrf_patterns => @project.getCSRFPatterns(),
                         :update_sids => @updateSID.checked?,
                         :follow_redirect => @followRedirect.checked?,
                         :egress_handler => egress_handler
        }

        prefs.update current_prefs
        logger("send request")

        @request_thread = Thread.new(new_request, prefs) { |nr, p|
          begin

            request, response = @request_sender.sendRequest(nr, p)

            #@chat_queue.push [last_request, last_response]
            Watobo.save_thread do
              logger("got answer")
              unless request.nil? then
                unless response.nil?
                  @response_viewer.setText response
                  @current_chat = Watobo::Chat.new(request, response, :source => CHAT_SOURCE_MANUAL, :run_passive_checks => false)

                  Watobo::Chats.add(@current_chat) if @logChat.checked? == true

                  @request_viewer.setText request
                  @last_request = request

                  @response_viewer.setText(response, :filter => true)
                  @responseMD5.text = response.contentMD5

                  addHistoryItem(@current_chat, @req_builder.rawRequest)

                  @history_pos_dt.value = @history.length
                  @history_pos.handle(self, FXSEL(SEL_UPDATE, 0), nil)
                end
              else
                logger("ERROR: #{@current_chat.response.first}") if @current_chat.respond_to? :response
                @responseMD5.text = "- N/A -"
              end
            end
          rescue => bang
            puts bang
          end
        }

      end

      def trans2Get(sender, sel, item)
        request = @req_builder.parseRequest
        return nil if request.nil?
        request = Watobo::Request.new request

        if request.method =~ /POST/i and request.content_type =~ /www\-form/i
          request.setMethod("GET")
          request.removeHeader("Content-Length")
          request.removeHeader("Content-Type")
          data = request.data.to_s
          #      puts "Data: "
          #      puts data
          request.appendQueryParms(data)
          request.setData('')
        end
        @req_builder.setRequest(request)
      end

      def trans2Post(sender, sel, item)
        request = @req_builder.parseRequest
        return nil if request.nil?
        request = Watobo::Request.new request

        if request.method =~ /GET/i
          request.setMethod("POST")
          request.set_header("Content-Length", "0")
          request.set_header("Content-Type", "application/x-www-form-urlencoded")
          data = request.query
          request.setData(data)
          request.removeUrlParms()

        end
        @req_builder.setRequest(request)
      end

      def simulatePressSendBtn()
        @btn_send.state = STATE_DOWN
        getApp().addTimeout(250, :repeat => false) do
            @btn_send.state = STATE_UP
        end
      end

      def hide()
        @scanner.cancel() if @scanner
        super
      end

    end
  end
end
