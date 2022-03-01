require 'watobo/gui/request_editor.rb'
require_relative './fuzzer_tree'
require_relative './filter_frame'
require_relative './fuzzer_check'

# @private 
module Watobo #:nodoc: all
  module Gui
    module Fuzzer

      class FuzzerTag

        attr :name
        attr :generators
        attr :collector
        attr :trigger

        def is_tag?()
          true
        end

        def addGenerator(gen)
          @generators.push gen
        end

        def deleteGenerator(gen)
          @generators.delete(gen)
        end

        def run(result)
          @generators.each do |g|
            g.run(result) { |x| yield x }
          end
        end

        def initialize(name)
          @name = name
          @generators = []
          @collector = nil
          @trigger = nil
        end
      end


      class Action
        attr :action_type
        attr :func
        attr :info

        def is_action?
          true
        end

        def initialize(action_proc, prefs)
          @func = action_proc
          @action_type = prefs[:action_type] || "undefined"
          @info = prefs[:info] || "undefined"
        end
      end

      class Filter
        attr :func
        attr :filter_type
        attr :value
        attr :info

        def is_filter?
          true
        end

        def initialize(filter_proc, prefs)
          @filter_type = prefs[:filter_type] || "undefined"
          @value = prefs[:value] || "undefined"
          @func = filter_proc
          @info = prefs[:info] || "undefined"
        end
      end

      class StatisticsFrame < FXVerticalFrame

        def clearView()
          @count_total = 0
          clearResponseCodeTable()
          clearResponseLengthTable()
        end

        def addResponse(response)

          @log_queue << response

        end

        def clearResponseCodeTable()
          @response_code_tbl.clearItems()
          @response_code_tbl.setTableSize(0, 2)

          @response_code_tbl.setColumnText(0, "STATUS")
          @response_code_tbl.setColumnText(1, "COUNT")

          @response_code_tbl.rowHeader.width = 0
          @response_code_tbl.setColumnWidth(0, 70)

          @response_code_tbl.setColumnWidth(1, 70)


        end

        def start_update_timer
          FXApp.instance.addTimeout(250, :repeat => true) {

            #print @log_queue.length
            while @log_queue.length > 0
              response = @log_queue.deq

              if response.respond_to? :status
                @count_total += 1
                @count_text.text = "Total: #{@count_total}"

                cstatus = response.status
                count_item = nil
                @response_code_tbl.getNumRows.times do |i|
                  rc_item = @response_code_tbl.getItem(i, 0)
                  count_item = @response_code_tbl.getItem(i, 1) if rc_item.text == response.status
                  break unless count_item.nil?
                end

                if count_item.nil?
                  lastRowIndex = @response_code_tbl.getNumRows
                  @response_code_tbl.appendRows(1)
                  @response_code_tbl.setItemText(lastRowIndex, 0, cstatus)
                  @response_code_tbl.setItemText(lastRowIndex, 1, "1")
                  count_item = @response_code_tbl.getItem(lastRowIndex, 1)
                else
                  c = count_item.text.to_i
                  count_item.text = (c + 1).to_s
                end
                @count_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              end

            end
          }

        end

        def clearResponseLengthTable()
          @response_length_tbl.clearItems()
          @response_length_tbl.setTableSize(0, 2)
          @response_length_tbl.columnHeader.height = 0
          @response_length_tbl.rowHeader.width = 0
          @response_length_tbl.setColumnWidth(0, 40)
          @response_length_tbl.setColumnWidth(1, 40)

          lastRowIndex = @response_length_tbl.getNumRows

          %w( MIN MAX AVRG ).each do |i|
            lastRowIndex = @response_length_tbl.getNumRows
            @response_length_tbl.appendRows(1)
            @response_length_tbl.setItemText(lastRowIndex, 0, i)
            @response_length_tbl.setItemText(lastRowIndex, 1, "0")
            @response_length_tbl.getItem(lastRowIndex, 0).justify = FXTableItem::LEFT
            @response_length_tbl.getItem(lastRowIndex, 1).justify = FXTableItem::LEFT
          end
        end


        def initialize(parent, opts)
          super(parent, opts)

          @log_queue = Queue.new

          @count_total = 0

          @count_text = FXLabel.new(self, "Total: 0")
          @count_text.setFont(FXFont.new(getApp(), "helvetica", 11, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))

          counter_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          response_code_gb = FXGroupBox.new(counter_frame, "Response Codes", LAYOUT_SIDE_BOTTOM | FRAME_GROOVE | LAYOUT_FILL_X | LAYOUT_FILL_Y, 0, 0, 0, 0)
          frame = FXVerticalFrame.new(response_code_gb, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
          @response_code_tbl = FXTable.new(sunken, :opts => FRAME_SUNKEN | TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)
          @response_code_tbl.columnHeader.connect(SEL_COMMAND) {}
          clearResponseCodeTable()

          response_length_gb = FXGroupBox.new(counter_frame, "Response Length", LAYOUT_SIDE_BOTTOM | FRAME_GROOVE | LAYOUT_FILL_Y, 0, 0, 0, 0)
          frame = FXVerticalFrame.new(response_length_gb, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
          @response_length_tbl = FXTable.new(sunken, :opts => FRAME_SUNKEN | TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)
          @response_length_tbl.columnHeader.connect(SEL_COMMAND) {}


          clearResponseLengthTable()

          start_update_timer
        end
      end





      class FuzzerGui < FXDialogBox

        include Watobo::Gui::Utils
        include Watobo::Gui::Icons
        include Watobo::Constants

        def onRequestReset(sender, sel, item)
          @requestEditor.setText(@request)
        end

        def hide()
          @scanner.cancel() if @scanner
          super
        end

        def listTags()
          tags = []
          tags.concat @sourceSelect.getTags()
          return tags
        end

        def initTable(table)
          table.clearItems()
          table.setTableSize(0, 2)
          table.visibleRows = 20
          table.rowHeader.width = 0
          table.setColumnText(0, "Tag/Value")
          table.setColumnText(1, "Match")
        end

        def selectLogDirectory(sender, sel, item)
          workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Log Directory", @log_dir_dt.value)
          if workspace_dt != "" then
            if File.exist?(workspace_dt) then
              @log_dir_dt.value = workspace_dt
              @log_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
          end
        end

        def saveMatches(sender, sel, ptr)
          begin
            # puts @project.settings[:session_path]
            # path = @project.settings[:session_path]+"/"
            filename = FXFileDialog.getSaveFilename(self, "Save file", nil, "All Files (*)")
            if filename != ""
              if File.exist?(filename)
                response = FXMessageBox.question(self, MBOX_YES_NO, "File exists", "Overwrite existing file?")
                return 0 if response != MBOX_CLICKED_YES

              end
              r = []
              @matchTable.numRows.times do |i|
                #puts items[1].to_s
                tv = @matchTable.getItemData(i, 0)
                data = @matchTable.getItemData(i, 1)
                if data
                  r << {:tag => tv, :data => data.strip}
                end
              end
              fh = File.new(filename, "w")
              fh.puts YAML.dump(r)
              fh.close
            end
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        def startSample(count)
          #TODO: Create and viewer for sample requests
        end

        def filterResponse(response, fuzzle)

          @filters.each do |f|
            matches = f.func.call(response) if f.func.respond_to? :call
            if matches.length > 0

              matches.each do |m|
                yield fuzzle, m
              end

            end
          end

        end

        def updateStatistics(request, response)

        end

        def addMatch(fuzzle, match)
          s = []
          fuzzle.each_pair do |k, v|
            s.push "#{k}=#{v}"
          end
          lastRowIndex = @matchTable.getNumRows
          @matchTable.appendRows(1)
          @matchTable.setItemText(lastRowIndex, 0, s.join("\n"))
          @matchTable.setItemData(lastRowIndex, 0, fuzzle)
          @matchTable.getItem(lastRowIndex, 0).justify = FXTableItem::LEFT
          @matchTable.fitRowsToContents(lastRowIndex)
          cell_text = match.gsub(/(\n+|\r+)/, " ")
          cell_text = (cell_text.slice(0..150) + "...").strip if match.length > 150
          @matchTable.setItemText(lastRowIndex, 1, cell_text)
          @matchTable.setItemData(lastRowIndex, 1, match)
          @matchTable.getItem(lastRowIndex, 1).justify = FXTableItem::LEFT
        end


        def startFuzzing()
          initTable(@matchTable)

          @log_viewer.log(LOG_INFO, "Prepare Fuzzing: Generators")
          check_list = []
          check_list << FuzzerCheck.new(@project, @fuzzer_tags, @filters, @requestEditor)

          # create dummy chat, not needed for fuzzing
          chat_list = []
          chat_list << Watobo::Chat.new(@chat.request, @chat.response, :source => CHAT_SOURCE_FUZZER, :id => 0)


          scan_prefs = @project.getScanPreferences
          # we don't want logout detection in manual requests ... yet
          scan_prefs[:logout_signatures] = []
          # scan_prefs[:csrf_requests] = @csrf_requests
          scan_prefs[:check_online] = false
          # check if logging all scan chat

          if @logScanChats.checked?
            scan_prefs[:scanlog_name] = @log_dir_dt.value unless @log_dir_dt.value.empty?
          end

          #  @scanner = Watobo::Scanner2.new(chat_list, check_list, @project.passive_checks, scan_prefs)
          @scanner = Watobo::Scanner3.new(chat_list, check_list, [], scan_prefs)
          @pbar.total = @scanner.sum_total
          @pbar.progress = 0
          @pbar.barColor = 'red'

          @scanner.subscribe(:progress) { |m|
            @pbar.increment(1)
          }

          @stat_viewer.clearView

          check_list.first.subscribe(:stats) { |response|
            @stat_viewer.addResponse(response)
          }

          check_list.first.subscribe(:fuzzer_match) { |fuzzle, request, response, match|
            @stat_viewer.addResponse(response)
            addMatch(fuzzle, match)

          }

          # Thread.new {
          begin
            m = "start fuzzing..."
            @log_viewer.log(LOG_INFO, m)
            scan_prefs = Hash.new
            scan_prefs[:update_session] = @updateSession.checked?
            scan_prefs[:run_passive_checks] = false
            scan_prefs[:update_content_length] = @updateContentLength.checked?

            puts scan_prefs.to_yaml
            puts "run scanner"
            @scanner.run(scan_prefs)
              #@fuzz_button.text = "Start"
              #@pbar.total = 0
              #@pbar.progress = 0
              #@pbar.barColor = 'grey'
              #m = "finished fuzzing!"
              #@log_viewer.log(LOG_INFO,m)
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
          # }

        end


        def initialize(owner, project, chat)
          # Invoke base class initialize function first
          super(owner, "Fuzzer", :opts => DECOR_ALL, :width => 800, :height => 600)
          self.icon = ICON_FUZZER
          @project = project
          @chat = chat
          @request = chat.request.dup
          @fuzzing_paused = false
          @fuzzing_started = false
          @scan_status_lock = Mutex.new

          #  @scan_prefs = @project.getScanPreferences()

          @numRunningChecks = 0

          @fuzzer_tags = []
          @filters = []
          @scanner = nil

          #  @fuzzels = FXDataTarget.new()

          mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | SPLITTER_VERTICAL | SPLITTER_REVERSED | SPLITTER_TRACKING)
          # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
          top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y || LAYOUT_FIX_HEIGHT | LAYOUT_BOTTOM, :height => 500)
          top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X | SPLITTER_HORIZONTAL | LAYOUT_FILL_Y | SPLITTER_TRACKING)

          log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_BOTTOM, :height => 100)

          #LAYOUT_FILL_X in combination with LAYOUT_FIX_WIDTH

          req_editor = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FIX_WIDTH | LAYOUT_FILL_Y | FRAME_GROOVE, :width => 400, :height => 500)


          req_edit_header = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X)
          FXLabel.new(req_edit_header, "Request:")
          req_viewer = FXVerticalFrame.new(req_editor, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
          req_reset_button = FXButton.new(req_edit_header, "Reset", nil, nil, 0, FRAME_RAISED | FRAME_THICK | LAYOUT_RIGHT)
          req_reset_button.connect(SEL_COMMAND, method(:onRequestReset))


          frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X | FRAME_GROOVE)
          @fuzz_button = FXButton.new(frame, "Start", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
          @fuzz_button.connect(SEL_COMMAND) { |sender, sel, data|
            if sender.text =~ /cancel/i then
              @fuzz_button.text = "Start"
              @log_viewer.log(LOG_INFO, "Fuzzing canceled!")
              @scanner.cancel if @scanner
              @pbar.progress = 0
              @pbar.total = 0
              @pbar.barColor = 0
              @pbar.barColor = 'grey' #FXRGB(255,0,0)
            else
              @fuzz_button.text = "Cancel"
              startFuzzing()
              @fuzz_button.text = "Start" if @scanner.nil?
            end
          }

          @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK | PROGRESSBAR_HORIZONTAL)

          @pbar.progress = 0
          @pbar.total = 0
          @pbar.barColor = 0
          @pbar.barColor = 'grey' #FXRGB(255,0,0)
          @requestEditor = FuzzRequestEditor.new(req_viewer, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
          @requestEditor.setText(@request)

          #  req_options = FXVerticalFrame.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          #eq_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)
          opt = FXGroupBox.new(req_editor, "Fuzzing Options", LAYOUT_SIDE_BOTTOM | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)

          #  opt = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
          #  btn = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
          #FXCheckButton.new(rob, "URL Encoding", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          @updateContentLength = FXCheckButton.new(opt, "Update Content-Length", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)
          @updateContentLength.checkState = true

          @updateSession = FXCheckButton.new(opt, "Update Session Information", nil, 0, JUSTIFY_LEFT | JUSTIFY_TOP | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)
          @updateSession.checkState = true

          #@updateSession.connect(SEL_COMMAND) do |sender, sel, item|
          #  @runLogin.enabled = @updateSession.checked?
          #end
          #  @runLogin = FXCheckButton.new(opt, "Run Login", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
          #  @runLogin.checkState = false

          @logScanChats = FXCheckButton.new(opt, "Log Scan", nil, 0, JUSTIFY_LEFT | JUSTIFY_TOP | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)
          @logScanChats.checkState = false
          @logScanChats.connect(SEL_COMMAND) do |sender, sel, item|
            if @logScanChats.checked? then
              @log_dir_text.enabled = true
              @log_dir_label.enabled = true
              # @log_dir_btn.enable
            else
              @log_dir_text.enabled = false
              @log_dir_label.enabled = false
              # @log_dir_btn.disable
            end
          end


          @log_dir_dt = FXDataTarget.new('')
          #   @log_dir_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())
          @log_dir_label = FXLabel.new(opt, "Scan Name:")
          scanlog_frame = FXHorizontalFrame.new(opt, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP)
          @log_dir_text = FXTextField.new(scanlog_frame, 20,
                                          :target => @log_dir_dt, :selector => FXDataTarget::ID_VALUE,
                                          :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN)
          @log_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          # @log_dir_btn = FXButton.new(scanlog_frame, "Change")
          # @log_dir_btn.connect(SEL_COMMAND, method(:selectLogDirectory))

          @log_dir_text.enabled = false
          @log_dir_label.enabled = false
          #@log_dir_btn.disable


          fuzz_setup_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE | LAYOUT_FIX_WIDTH, :width => 400)

          @tabBook = FXTabBook.new(fuzz_setup_frame, nil, 0, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_RIGHT)

          FXTabItem.new(@tabBook, "Settings", nil)
          rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
          frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN, :padding => 0)
          @fuzzer_tree = FuzzerTree.new(frame, @project)

          @fuzzer_tree.subscribe(:new_tag) do |tag|
            @fuzzer_tags.push tag
            @requestEditor.addTag(tag.name)
            @requestEditor.highlightTags()
          end

          @fuzzer_tree.subscribe(:remove_tag) do |tag|
            @fuzzer_tags.delete(tag)
            @requestEditor.removeTag(tag.name)
            @requestEditor.highlightTags()
          end

          @fuzzer_tree.subscribe(:new_filter) do |filter|
            @filters.push filter
          end

          @fuzzer_tree.subscribe(:remove_filter) do |filter|
            @filters.delete(filter)
          end

          FXTabItem.new(@tabBook, "Results", nil)
          rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
          frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN, :padding => 0)
          @matchTable = FXTable.new(frame, :opts => TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)
          initTable(@matchTable)

          btnframe = FXHorizontalFrame.new(rframe, :opts => LAYOUT_FILL_X | FRAME_SUNKEN)
          button = FXButton.new(btnframe, "Save Matches", nil, nil, 0, FRAME_RAISED | FRAME_THICK)

          button.connect(SEL_COMMAND, method(:saveMatches))

          FXTabItem.new(@tabBook, "Statistics", nil)
          statframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
          @stat_viewer = StatisticsFrame.new(statframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED, :padding => 0)
          FXVerticalFrame.new(statframe, :opts => LAYOUT_FILL_X | LAYOUT_FIX_HEIGHT | FRAME_NONE, :height => 250)

          log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
          FXLabel.new(log_frame_header, "Logs:")
          log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_GROOVE, :padding => 0)
          @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)

          add_update_timer(250)

        end

        def add_update_timer(ms)
          FXApp.instance.addTimeout(ms, :repeat => true) {
            unless @scanner.nil?
              @scan_status_lock.synchronize do

                if @pbar.total > 0
                  sum_progress = 0
                  @scanner.progress.each_value do |v|
                    sum_progress += v[:progress]
                  end
                  @pbar.progress = sum_progress
                end

                if @scanner.finished?
                  @scanner = nil
                  #logger("Scan Finished!")
                  @log_viewer.log(LOG_INFO, "Done fuzzing!")
                  @pbar.progress = 0
                  @pbar.total = 0
                  @pbar.barColor = 'grey' #FXRGB(255,0,0)
                  # @btn_quickscan.text = "QuickScan"
                end
              end

            end
          }
        end
      end


      # namespace end
    end
  end
end
