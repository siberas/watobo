require 'watobo/gui/request_editor.rb'
# @private 
module Watobo #:nodoc: all


  module Gui

    class FuzzerCheck < Watobo::ActiveCheck

      def initialize(project, fuzzer_list, filter_list, requestEditor, prefs={})
        super(project.object_id, prefs)
        @fuzzer_list = fuzzer_list
        @requestEditor = requestEditor
        @filter_list = filter_list
        @prefs = prefs
      end

      def fuzzels(fuzzers, index=0, result=nil)
        begin
          unless fuzzers[index].nil?
            fuzzers[index].run(result) do |fuzz|
              if index < fuzzers.length - 1
                fuzzels(fuzzers, index+1, fuzz) do |sr|
                  yield sr
                end
              else
                yield fuzz
              end
            end
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end


      def reset()

      end

      def generateChecks(chat)
        unless @fuzzer_list.empty?
          fuzzels(@fuzzer_list) do |fuzzle|
            test_fuzzle = Hash.new
            test_fuzzle.update YAML.load(YAML.dump(fuzzle))
            checker = proc {
              #puts test_fuzzle
              fuzz_request = @requestEditor.parseRequest(test_fuzzle)
              fuzz_request.extend Watobo::Mixin::Shaper::Web10
              fuzz_request.extend Watobo::Mixin::Parser::Web10
              fuzz_request.extend Watobo::Mixin::Parser::Url

              test_request, test_response = doRequest(fuzz_request, @prefs)

              notify(:stats, test_response)

              notify(:fuzzer_match, test_fuzzle, test_request, test_response, test_response.join) if @filter_list.empty?

              @filter_list.each do |f|
                matches = f.func.call(test_response) if f.func.respond_to? :call
                matches.each do |match|
                  notify(:fuzzer_match, test_fuzzle, test_request, test_response, match)
                end
              end

              [test_request, test_response]
            }
            yield checker
          end
        end
      end
    end

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


    class CreateFuzzerDlg < FXDialogBox

      def tag
        @tag_dt.value
      end

      def initialize(owner)
        super(owner, "Create New Tag", DECOR_TITLE|DECOR_BORDER)
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Enter Label For Tag:")
        input = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        @tag_dt = FXDataTarget.new('')
        @tag_text = FXTextField.new(input, 1, :target => @tag_dt, :selector => FXDataTarget::ID_VALUE,
                                    :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)

        FXLabel.new(main, "Note:\nTo define the position in the request enclose the tag name\nbetween '%%', eg. '%%tag%%'.\nIt will turn green if the given tag name is correct.\n" +
            "Don't forget to specify a generator!").justify = JUSTIFY_LEFT

        @tag_text.setFocus()
        @tag_text.setDefault()

        @tag_dt.connect(SEL_COMMAND) {
          @accept_btn.setFocus()
          @accept_btn.setDefault()
        }
        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
                                        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
        # Accept
        @accept_btn = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end
    end

    class CreateActionDlg < FXDialogBox

      def getAction()
        return @actionSelection.createAction()
      end

      def initialize(owner)
        super(owner, "Create Action", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 500)
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @actionSelection = ActionSelect.new(main, self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding => 0)

        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH, :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
        # Accept
        accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end
    end

    class CreateGeneratorDlg < FXDialogBox

      def getGenerator(fuzzer)
        return @fuzzerSelection.createGenerator(fuzzer)
      end

      def initialize(owner)
        super(owner, "Create Generator", DECOR_TITLE|DECOR_BORDER)
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding => 0)

        @fuzzerSelection = FuzzerGenSelect.new(main, self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding => 0)

        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
                                        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
        # Accept
        accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
                              FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
                     FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end
    end

    class CreateFilterDlg < FXDialogBox

      def filter()
        return @filterFrame.selection()
      end

      def initialize(owner, project)
        super(owner, "Create Filter", DECOR_TITLE|DECOR_BORDER)
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding => 0)

        @filterFrame = FilterFrame.new(main, project.getSidPatterns, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding => 0)

        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
                                        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
        # Accept
        accept = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
                              FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)

        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
                     FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end
    end

    class FuzzRequestEditor < Watobo::Gui::RequestEditor

      def highlight(pattern)
        sindex = nil
        eindex = nil

        dummy = @textbox.to_s
        @textbox.setText(dummy)

        pos = 0
        @pattern_matches.clear

        loop do

          sindex, eindex = @textbox.findText(pattern, pos, SEARCH_EXACT|SEARCH_IGNORECASE|SEARCH_FORWARD)
          #   puts sindex
          sindex, eindex = @textbox.findText(pattern, pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex
          #  puts sindex
          sindex, eindex = @textbox.findText(Regexp.quote(pattern), pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex

          break if not sindex or sindex.length == 0


          pos = eindex.last+1

          sindex.length.times do |i|
            start = sindex[i]
            len = eindex[i] - sindex[i]
            @pattern_matches.push [start, len] if start >= 0

          end

          break if sindex.last < 0
          #   puts sindex

        end

        # puts "* found pattern #{pattern} #{@pattern_matches.length} times"

        @pattern_matches.each do |start, len|
          begin
            style = @style
            match = @textbox.to_s.slice(start, len)
            # puts "#{match}/#{start}/#{len}"
            match.gsub!(/%%/, '')
            style = @tags.include?(match) ? 1 : 2

            @textbox.changeStyle(start, len, style)
          rescue => bang
            puts "outch"
            puts bang
          end
        end
        return @pattern_matches
      end


      def parseRequest(fuzzels)
        begin
          new_request = nil
          if fuzzels then
            new_request = @textbox.to_s
            fuzzels.each do |marker, value|
              new_request.gsub!(/%%#{marker}%%/, value.to_s)
            end
          end

          return Watobo::Utils.text2request(new_request)
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def addTag(tag)
        @tags.push tag
      end

      def removeTag(tag)
        @tags.delete(tag)
      end

      def highlightTags()
        highlight("(%%[^%]*%%)")
      end

      def initialize(owner, opts)
        super(owner, opts)

        @tags = []

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

        counter_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        response_code_gb = FXGroupBox.new(counter_frame, "Response Codes", LAYOUT_SIDE_BOTTOM|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(response_code_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @response_code_tbl = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        @response_code_tbl.columnHeader.connect(SEL_COMMAND) {}
        clearResponseCodeTable()

        response_length_gb = FXGroupBox.new(counter_frame, "Response Length", LAYOUT_SIDE_BOTTOM|FRAME_GROOVE|LAYOUT_FILL_Y, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(response_length_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        sunken = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @response_length_tbl = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        @response_length_tbl.columnHeader.connect(SEL_COMMAND) {}


        clearResponseLengthTable()

        start_update_timer
      end
    end

    class FilterFrame < FXVerticalFrame

      def selection()
        filter = case @filter_dt.value
                   when 0
                     index = @patternCombo.currentItem
                     if @patternCombo.getItemText(index)
                       func = proc { |response|
                         pattern = @patternCombo.getItemText(index)
                         matchlist = []
                         response.each do |line|
                           if line =~ /#{pattern}/i then
                             match = $2
                             matchlist.push "#{match}"
                           end
                         end
                         matchlist
                       }
                       Filter.new(func, :filter_type => "SID", :value => "#{filter}", :info => "#{@patternCombo.getItemText(index)}")
                     else
                       nil
                     end

                   when 1

                     if @regex_filter_dt.value != '' then
                       func = proc { |response|
                         pattern = @regex_filter_dt.value
                         matchlist = []
                         # puts "...regex (#{pattern})..."
                         # puts response
                         #response.each do |line|
                         #if line =~ /#{pattern}/i then
                         if @negate_regex_cb.checked?
                           puts "* filter negate regex"
                           unless response.join =~ /#{pattern}/i then
                             match = $1
                             puts "* #{match}"
                             match = "#{response.join}" unless match
                             matchlist.push "#{match}"
                           end
                         else
                           if response.join =~ /#{pattern}/i then
                             match = $1
                             puts "* #{match}"
                             match = "#{response.join}" unless match
                             matchlist.push "#{match}"
                           end
                         end
                         #end
                         matchlist
                       }
                       Filter.new(func, :filter_type => "Regex", :value => "#{filter}", :info => "#{@regex_filter_dt.value}")
                     else
                       nil
                     end
                 end
        return filter
      end


      def initialize(owner, sidpatterns, opts)
        @sid_patterns = sidpatterns
        super(owner, opts)

        @filter_dt = FXDataTarget.new(0)
        group_box = FXGroupBox.new(self, "Filter", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        sid_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
        @sid_rb = FXRadioButton.new(sid_frame, "Session-ID", @filter_dt, FXDataTarget::ID_OPTION)

        regex_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
        @regex_rb = FXRadioButton.new(regex_frame, "Regex", @filter_dt, FXDataTarget::ID_OPTION + 1)
        @regex_filter_dt = FXDataTarget.new('')
        @regex_filter = FXTextField.new(regex_frame, 1, :target => @regex_filter_dt, :selector => FXDataTarget::ID_VALUE,
                                        :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        @negate_regex_cb = FXCheckButton.new(group_box, "negate", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP|LAYOUT_RIGHT|LAYOUT_FILL_Y)
        # group_box = FXGroupBox.new(self, "Collection",LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        # frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_GROOVE)
        # @collectionList = FXList.new(frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @filter_dt.connect(SEL_COMMAND) {
          @sid_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }

        if @sid_patterns then
          @patternCombo = FXComboBox.new(sid_frame, @sid_patterns.length, nil, 0,
                                         :opts => COMBOBOX_INSERT_LAST|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          @patternCombo.numVisible = @sid_patterns.length
          @sid_patterns.each do |pattern|
            @patternCombo.appendItem(pattern, nil)
          end
        else
          FXLabel.new(sid_frame, "NO SID PATTERNS DEFINED!")
          @sid_rb.disable
          @filter_dt.value = 1
          @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end

        @sid_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  group_box = FXGroupBox.new(self, "Test", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        #  @sample_count_dt = FXDataTarget.new('')
        #  frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
        #  @sample_count = FXTextField.new(frame, 3, :target => @sample_count_dt, :selector => FXDataTarget::ID_VALUE,
        #                                  :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
        #  button = FXButton.new(frame, "Sample", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
        #  button.connect(SEL_COMMAND) do  |sender, sel, ptr|
        #    @interface.startSample()
        #  end
        #  frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
        #  FXLabel.new(frame, "Matched:")


      end
    end

    class FuzzerGenSelect < FXVerticalFrame

      include Watobo

      def updateFields
        @file_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @gen_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @list_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @sourceFileText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @cstartText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @cstopText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @cstepText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def selectFile(sender, sel, ptr)
        filename = FXFileDialog.getOpenFilename(self, "Select Source File", @source_file.value)
        if filename != "" then
          if File.exist?(filename) then
            @source_file.value = filename
            @sourceFileText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end

        end
      end

      def onValueSelect(sender, sel, selected)
        item = @valueList.currentItem
        if item >= 0 then
          @new_list_item_dt.value = @valueList.getItemText(item)
        end
      end

      def removeValue(sender, sel, ptr)
        item = @valueList.currentItem
        if item >= 0 then
          @valueList.removeItem(item)
        end
      end

      def addValue(sender, sel, ptr)
        if @new_list_item_dt.value != '' then
          index = @valueList.appendItem(@new_list_item_dt.value)
          @valueList.makeItemVisible(index)
          @new_list_item_dt.value = ''
          @new_list_item.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end
      end

      def createGenerator(fuzzer)
        gen = case @source_dt.value
                when 0
                  #puts "File Generator Selected"
                  Watobo::FuzzFile.new(fuzzer,
                                       @source_file.value)
                when 1
                  # counter selected
                  Watobo::FuzzCounter.new(fuzzer,
                                          :start => @cstart.value.to_i,
                                          :stop => @cstop.value.to_i,
                                          #:count => @ccount.value.to_i,
                                          :step => @cstep.value.to_i)
                when 2

                  list = []
                  @valueList.each do |item|
                    # puts item
                    list.push item.text
                  end
                  Watobo::FuzzList.new(fuzzer, list)
              end

        return gen
      end

      def disableFrame(frame)
        frame.children.each do |c|
          c.children.each do |sc|
            sc.disable
            sc.selBackColor = sc.parent.backColor if sc.respond_to? :selBackColor
          end
          c.disable
          c.selBackColor = c.parent.backColor if c.respond_to? :selBackColor
        end
      end

      def enableFrame(frame)
        frame.children.each do |c|
          c.children.each do |sc|
            sc.enable
            sc.selBackColor = FXColor::White if sc.respond_to? :selBackColor
          end
          c.enable
          c.selBackColor = FXColor::White if c.respond_to? :selBackColor
        end
      end

      def initialize(owner, interface, opts)
        super(owner, opts)

        @interface = interface

        group_box = FXGroupBox.new(self, "Select Source", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        @source_dt = FXDataTarget.new(0)

        @source_dt.connect(SEL_COMMAND) do
          case @source_dt.value
            when 0
              # puts "File"
              enableFrame(@file_select_frame)
              disableFrame(@counter_frame)
              disableFrame(@list_frame)
            when 1
              disableFrame(@file_select_frame)
              disableFrame(@list_frame)
              enableFrame(@counter_frame)
            # puts "Generator"
            when 2
              disableFrame(@counter_frame)
              enableFrame(@list_frame)
              disableFrame(@file_select_frame)
            # puts "List"
          end
          @file_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @gen_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @list_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end
        file_rb_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
        @file_rb = FXRadioButton.new(file_rb_frame, "File", @source_dt, FXDataTarget::ID_OPTION)

        @file_select_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X, :padding => 0)
        @source_file = FXDataTarget.new('')
        @sourceFileText = FXTextField.new(@file_select_frame, 1, :target => @source_file, :selector => FXDataTarget::ID_VALUE,
                                          :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        button = FXButton.new(@file_select_frame, "Select")
        button.connect(SEL_COMMAND, method(:selectFile))

        counter_rb_frame = FXHorizontalFrame.new(group_box, LAYOUT_FILL_X)
        @gen_rb = FXRadioButton.new(counter_rb_frame, "Counter", @source_dt, FXDataTarget::ID_OPTION + 1)
        @counter_frame = FXHorizontalFrame.new(group_box, LAYOUT_FILL_X, :padding => 0)

        @cstep = FXDataTarget.new(0)
        @cstepText = FXTextField.new(@counter_frame, 3, :target => @cstep, :selector => FXDataTarget::ID_VALUE,
                                     :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        FXLabel.new(@counter_frame, "Step", nil, :opts => LAYOUT_RIGHT)


        @cstop = FXDataTarget.new(0)
        @cstopText = FXTextField.new(@counter_frame, 3, :target => @cstop, :selector => FXDataTarget::ID_VALUE,
                                     :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        FXLabel.new(@counter_frame, "Stop", nil, :opts => LAYOUT_RIGHT)


        @cstart = FXDataTarget.new(0)
        @cstartText = FXTextField.new(@counter_frame, 3, :target => @cstart, :selector => FXDataTarget::ID_VALUE,
                                      :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
        FXLabel.new(@counter_frame, "Start", nil, :opts => LAYOUT_RIGHT)

        list_rb_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @list_rb = FXRadioButton.new(list_rb_frame, "List", @source_dt, FXDataTarget::ID_OPTION + 2)
        @list_frame = FXVerticalFrame.new(list_rb_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        frame = FXHorizontalFrame.new(@list_frame, :opts => LAYOUT_FILL_X, :padding => 0)

        @new_list_item_dt = FXDataTarget.new('')
        @new_list_item = FXTextField.new(frame, 10,
                                         :target => @new_list_item_dt, :selector => FXDataTarget::ID_VALUE,
                                         :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        #   FXLabel.new(frame, "Value: ")
        @addButton = FXButton.new(frame, "Add", nil, nil, 0, :opts => FRAME_RAISED|FRAME_THICK)
        @addButton.connect(SEL_COMMAND, method(:addValue))
        @remButton = FXButton.new(frame, "Remove", nil, nil, 0, :opts => FRAME_RAISED|FRAME_THICK)
        @remButton.connect(SEL_COMMAND, method(:removeValue))

        list_border = FXVerticalFrame.new(@list_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_GROOVE, :padding => 0)
        @valueList = FXList.new(list_border, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @valueList.numVisible = 4

        @valueList.connect(SEL_COMMAND, method(:onValueSelect))

        enableFrame(@file_select_frame)
        disableFrame(@counter_frame)
        disableFrame(@list_frame)

        updateFields()

      end
    end

    class ActionSelect < FXVerticalFrame
      include Watobo

      def updateFields
        @b64_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @url_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @md5_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @ruby_proc_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)

      end

      def createAction()
        action = case @source_dt.value
                   when 0
                     action_proc = proc { |input| Base64.encode64(input) }
                     Action.new(action_proc, :action_type => 'Encode: Base64')
                   when 1
                     action_proc = proc { |input| CGI::escape(input) }
                     Action.new(action_proc, :action_type => 'Encode: URL')
                   when 2
                     action_proc = proc { |input| Digest::MD5.hexdigest(input) }
                     Action.new(action_proc, :action_type => 'Hash: MD5')
                   when 3
                     begin
                       #  puts "* Action: Proc"
                       # puts @textbox.to_s
                       code = @textbox.to_s
                       action_proc = eval(code)
                         # puts action_proc

                     rescue SyntaxError => bang
                       puts bang
                       puts code
                     rescue LocalJumpError => bang
                       puts bang
                       puts code
                     rescue SecurityError => bang
                       puts "desired functionality forbidden. it may harm your system!"
                       puts code
                     rescue => bang
                       puts bang
                       puts code

                     end
                     if action_proc
                       Action.new(action_proc, :action_type => "Ruby: Proc", :info => "#{@textbox.to_s}")
                     else
                       nil
                     end
                 end

        return action
      end


      def initialize(owner, interface, opts)
        super(owner, opts)

        @interface = interface

        group_box = FXGroupBox.new(self, "Select Action", LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        @source_dt = FXDataTarget.new(0)

        @source_dt.connect(SEL_COMMAND) do
          @b64_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @url_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @md5_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @ruby_proc_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          if @source_dt.value != 3
            @textbox.enabled = false
            @textbox.backColor = FXColor::LightGrey
          else
            @textbox.enabled = true
            @textbox.backColor = FXColor::White
          end

        end

        begin
          frame = FXVerticalFrame.new(group_box, LAYOUT_FILL_X)
          @b64_rb = FXRadioButton.new(frame, "Encode Base64", @source_dt, FXDataTarget::ID_OPTION)

          frame = FXVerticalFrame.new(group_box, LAYOUT_FILL_X)
          @url_rb = FXRadioButton.new(frame, "Encode URL", @source_dt, FXDataTarget::ID_OPTION + 1)
          #      @textbox = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 100, :height => 100)

          frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          @md5_rb = FXRadioButton.new(frame, "Hash MD5", @source_dt, FXDataTarget::ID_OPTION + 2)

          frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @ruby_proc_rb = FXRadioButton.new(frame, "Ruby Proc", @source_dt, FXDataTarget::ID_OPTION + 3)
          text_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_SUNKEN, :padding => 0)
          @textbox = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 100, :height => 100)
          proc_skeleton = "proc { |input|\n# place your code betweenhere\n# e.g. 'input + \"TAIL\"\n\n\n# and here\n}"
          @textbox.setText(proc_skeleton)
          @textbox.enabled = false
          @textbox.backColor = FXColor::LightGrey


            # @textbox.editable = true
        rescue => bang
          puts "AAAAAA"
          puts bang
        end
        updateFields()

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

        mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
        # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
        top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y||LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM, :height => 500)
        top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)

        log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM, :height => 100)

        #LAYOUT_FILL_X in combination with LAYOUT_FIX_WIDTH

        req_editor = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FIX_WIDTH|LAYOUT_FILL_Y|FRAME_GROOVE, :width => 400, :height => 500)


        req_edit_header = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X)
        FXLabel.new(req_edit_header, "Request:")
        req_viewer = FXVerticalFrame.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        req_reset_button = FXButton.new(req_edit_header, "Reset", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
        req_reset_button.connect(SEL_COMMAND, method(:onRequestReset))


        frame = FXHorizontalFrame.new(req_editor, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        @fuzz_button = FXButton.new(frame, "Start", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
        @fuzz_button.connect(SEL_COMMAND) { |sender, sel, data|
          if sender.text =~ /cancel/i then
            @fuzz_button.text = "Start"
            @log_viewer.log(LOG_INFO, "Fuzzing canceled!")
            @scanner.cancel if @scanner
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)
          else
            @fuzz_button.text = "Cancel"
            startFuzzing()
            @fuzz_button.text = "Start" if @scanner.nil?
          end
        }

        @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)

        @pbar.progress = 0
        @pbar.total = 0
        @pbar.barColor=0
        @pbar.barColor = 'grey' #FXRGB(255,0,0)
        @requestEditor = FuzzRequestEditor.new(req_viewer, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @requestEditor.setText(@request)

        #  req_options = FXVerticalFrame.new(req_editor, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        #eq_options = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)
        opt = FXGroupBox.new(req_editor, "Fuzzing Options", LAYOUT_SIDE_BOTTOM|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)

        #  opt = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #  btn = FXVerticalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #FXCheckButton.new(rob, "URL Encoding", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @updateContentLength = FXCheckButton.new(opt, "Update Content-Length", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @updateContentLength.checkState = true

        @updateSession = FXCheckButton.new(opt, "Update Session Information", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        @updateSession.checkState = true

        #@updateSession.connect(SEL_COMMAND) do |sender, sel, item|
        #  @runLogin.enabled = @updateSession.checked?
        #end
        #  @runLogin = FXCheckButton.new(opt, "Run Login", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #  @runLogin.checkState = false

        @logScanChats = FXCheckButton.new(opt, "Log Scan", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
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
        scanlog_frame = FXHorizontalFrame.new(opt, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        @log_dir_text = FXTextField.new(scanlog_frame, 20,
                                        :target => @log_dir_dt, :selector => FXDataTarget::ID_VALUE,
                                        :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
        @log_dir_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        # @log_dir_btn = FXButton.new(scanlog_frame, "Change")
        # @log_dir_btn.connect(SEL_COMMAND, method(:selectLogDirectory))

        @log_dir_text.enabled = false
        @log_dir_label.enabled = false
        #@log_dir_btn.disable


        fuzz_setup_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE|LAYOUT_FIX_WIDTH, :width => 400)

        @tabBook = FXTabBook.new(fuzz_setup_frame, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

        FXTabItem.new(@tabBook, "Settings", nil)
        rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
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
        rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
        @matchTable = FXTable.new(frame, :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        initTable(@matchTable)

        btnframe = FXHorizontalFrame.new(rframe, :opts => LAYOUT_FILL_X|FRAME_SUNKEN)
        button = FXButton.new(btnframe, "Save Matches", nil, nil, 0, FRAME_RAISED|FRAME_THICK)

        button.connect(SEL_COMMAND, method(:saveMatches))

        FXTabItem.new(@tabBook, "Statistics", nil)
        statframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @stat_viewer = StatisticsFrame.new(statframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED, :padding => 0)
        FXVerticalFrame.new(statframe, :opts => LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT|FRAME_NONE, :height => 250)

        log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(log_frame_header, "Logs:")
        log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_GROOVE, :padding => 0)
        @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        add_update_timer(250)

      end

      def add_update_timer(ms)
       Watobo.save_thread{
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

    class FuzzerTree < FXTreeList
      attr :fuzzTags
      include Watobo::Gui::Icons

      def setup_listeners
        @event_dispatcher_listeners = {}

      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end


      def addFilterItem(filter)

        filter_root = self.findItem("Filters", nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

        filter_item = self.appendItem(filter_root, "Filter: #{filter.filter_type}")
        self.setItemData(filter_item, filter)
        self.appendItem(filter_item, filter.info)
      end


      def addTag()
        dlg = Watobo::Gui::CreateFuzzerDlg.new(self)
        if dlg.execute != 0 then
          tag = dlg.tag
          tag_is_valid = true
          @fuzzTags.each do |f|
            tag_is_valid = false if f.name == tag
          end
          if tag_is_valid and tag != ""
            new_fuzz_tag = FuzzerTag.new(tag)
            @fuzzTags.push new_fuzz_tag
            notify(:new_tag, new_fuzz_tag)
            refresh()
          else
            puts "!!! Could not create empty/used tag !!!"
          end
        end
      end

      def addTagItem(tag)

        tag_root = self.findItem("Tags", nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

        item = self.findItem(tag.name, tag_root, SEARCH_FORWARD|SEARCH_IGNORECASE)

        return nil if item
        tag_item = self.appendItem(tag_root, "Tag: #{tag.name}")
        self.setItemData(tag_item, tag)

        #   item = self.appendItem(fuzz_item, "Generator", ICON_VULN, ICON_VULN)
        #  self.setItemData(item, :generator)

        tag.generators.each do |gen|
          addGeneratorItem(tag_item, gen)
        end


      end

      def initTree()
        fuzz_item = self.appendItem(nil, "Tags", ICON_FUZZ_TAG, ICON_FUZZ_TAG)
        self.setItemData(fuzz_item, :tags)

        item = self.appendItem(nil, "Filters", ICON_FUZZ_FILTER, ICON_FUZZ_FILTER)
        self.setItemData(item, :filter)

        #item = self.appendItem(nil, "Collector", ICON_INFO, ICON_INFO)
        #self.setItemData(item, :collector)
      end

      def addAction(generator)
        dlg = Watobo::Gui::CreateActionDlg.new(self)
        if dlg.execute != 0 then
          puts "new action"
          new_action = dlg.getAction()
          generator.addAction(new_action) if new_action
          refresh()
        end
      end

      def addGeneratorItem(tag_item, generator)
        begin
          item = self.appendItem(tag_item, generator.genType, ICON_FUZZ_GENERATOR, ICON_FUZZ_GENERATOR)
          self.setItemData(item, generator)
          self.appendItem(item, generator.info)

          generator.actions.each do |a|
            action_item = self.appendItem(item, a.action_type, ICON_FUZZER, ICON_FUZZER)
            self.setItemData(action_item, a)
            self.appendItem(action_item, a.info)
          end
          self.expandTree(item)
        rescue => bang
          puts "!ERROR: could not add GeneratorItem"
          puts bang
        end
      end

      def expandSubtree(item=nil)
        if item
          self.expandTree(item)
          item.each do |child|
            expandSubtree(child)
          end
        end
      end

      def expandSettings(item=nil)
        self.each do |root_item|
          expandSubtree(root_item)
        end
      end

      def refresh()
        self.clearItems()
        initTree()
        @fuzzTags.each do |f|
          addTagItem(f)
        end

        @filters.each do |f|
          addFilterItem(f)
        end

        expandSettings()
      end

      def initialize(owner, project)
        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT)
        #  f = Fuzzer.new("FUZZ")
        @fuzzTags = []
        @project = project
        @filters = []

        setup_listeners()

        refresh()


        self.connect(SEL_COMMAND) do |sender, sel, item|
          if self.itemLeaf?(item)
            getApp().beginWaitCursor do
              begin
                if item.data
                  if item.data.is_a? Finding
                    @interface.show_vuln(item.data)
                  end
                end
              rescue => bang
                puts "!!! Error: could not show selected finding"
                puts bang
              end
            end
          elsif item.data == :title then
            @interface.show_vuln(item.first.data) if item.first.data
          end
        end

        self.connect(SEL_DOUBLECLICKED) do |sender, sel, item|
          if self.itemLeaf?(item)
            begin
              if item.data and item.data.is_a? Symbol then
                case item.data
                  when :tags
                    addTag()
                  when :filter
                    dlg = Watobo::Gui::CreateFilterDlg.new(self, @project)
                    if dlg.execute != 0 then
                      f = dlg.filter
                      notify(:new_filter, f)
                      @filters.push f
                      refresh()
                    end
                end
              elsif item.data.respond_to? :is_tag?
                dlg = Watobo::Gui::CreateGeneratorDlg.new(self)
                if dlg.execute != 0 then
                  # puts "new generator"
                  fuzzer = item.data
                  gen = dlg.getGenerator(fuzzer)
                  fuzzer.addGenerator(gen)
                  refresh()
                end
              elsif item.data.respond_to? :is_generator?
                gen = item.data
                addAction(gen)

              else
                puts "Unknown Object: #{item.data.class}"
              end

            rescue => bang
              puts "!!! Error: could not show selected finding"
              puts bang
            end
          end
        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            item = sender.getItemAt(event.win_x, event.win_y)

            FXMenuPane.new(self) do |menu_pane|
              data = item ? self.getItemData(item) : nil
              if data.is_a? Symbol
                case data
                  when :tags

                    m = FXMenuCommand.new(menu_pane, "Add Tag..")
                    m.connect(SEL_COMMAND) {
                      addTag()
                    }

                  when :filter

                    m = FXMenuCommand.new(menu_pane, "Add Filter..")
                    m.connect(SEL_COMMAND) {
                      dlg = Watobo::Gui::CreateFilterDlg.new(self, @project)
                      if dlg.execute != 0 then
                        f = dlg.filter
                        notify(:new_filter, f)
                        @filters.push f
                        refresh()
                      end
                    }
                end
              elsif data.respond_to? :is_tag?
                m = FXMenuCommand.new(menu_pane, "Add Generator..")
                m.connect(SEL_COMMAND) {
                  dlg = Watobo::Gui::CreateGeneratorDlg.new(self)
                  if dlg.execute != 0 then
                    # puts "new generator"
                    fuzzer = data
                    gen = dlg.getGenerator(fuzzer)
                    fuzzer.addGenerator(gen)
                    refresh()
                  end
                }
                m = FXMenuCommand.new(menu_pane, "Remove Tag")
                m.connect(SEL_COMMAND) {
                  # puts "Removing Tag [#{data.name}]"
                  if @fuzzTags.include?(data)
                    # puts "...found tag"
                    @fuzzTags.delete(data)
                  end
                  notify(:remove_tag, data)
                  refresh()
                }
              elsif data.respond_to? :is_generator?
                m = FXMenuCommand.new(menu_pane, "Add Action..")
                m.connect(SEL_COMMAND) {
                  gen = self.getItemData(item)
                  addAction(gen)
                }
                m = FXMenuCommand.new(menu_pane, "Remove Generator")
                m.connect(SEL_COMMAND) {
                  tag = self.getItemData(item.parent)
                  tag.deleteGenerator(data)
                  refresh()
                }
              elsif data.respond_to? :is_action?
                m = FXMenuCommand.new(menu_pane, "Remove Action")
                m.connect(SEL_COMMAND) {
                  gen = self.getItemData(item.parent)
                  gen.removeAction(data)
                  refresh()
                }
              elsif data.respond_to? :is_filter?
                m = FXMenuCommand.new(menu_pane, "Remove Filter")
                m.connect(SEL_COMMAND) {
                  @filters.delete(data)
                  notify(:remove_filter, data)
                  refresh()
                }
              else
                puts "Unknown Object: #{data.class}"
              end

              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)


              app.runModalWhileShown(menu_pane)
            end
          end
        end
      end
    end
    # namespace end
  end

end
