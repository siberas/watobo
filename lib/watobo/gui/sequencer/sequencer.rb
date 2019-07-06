module Watobo
  module Gui
    class SequencerDlg < FXDialogBox

      @@save_dir = Watobo.workspace_path

      include Watobo::Constants
      include Watobo::Gui::Icons

      def settings
        {
            :name => @seq_name_dt.value,
            :sequence => @sequence.map {|e| e.to_h}
        }
      end

      def initialize(owner)
        # Invoke base class initialize function first

        super(owner, "Sequencer", :opts => DECOR_ALL, :width => 850, :height => 600)
        self.icon = ICON_SEQUENCER

        @seq_name_dt = FXDataTarget.new('Untitled')
        @seq_name_dt.connect(SEL_CHANGED) do
          update_title
        end

        @sequence = []
        @active_element = nil


        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
        ctrl_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X | FRAME_GROOVE, :height => 500)
        FXLabel.new(ctrl_frame, "Name", :opts => LAYOUT_CENTER_Y)
        @filter_text = FXTextField.new(ctrl_frame, 15,
                                       :target => @seq_name_dt, :selector => FXDataTarget::ID_VALUE,
                                       :opts => FRAME_SUNKEN | FRAME_THICK | LAYOUT_FILL_Y)
        button = FXButton.new(ctrl_frame, "Run Sequence", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        button.connect(SEL_COMMAND) {run_sequence}
        @logChat = FXCheckButton.new(ctrl_frame, "Log Chat", nil, 0,
                                     ICON_BEFORE_TEXT | LAYOUT_CENTER_Y)
        @logChat.checkState = false
        @load_btn = FXButton.new(ctrl_frame, "Load", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        @save_btn = FXButton.new(ctrl_frame, "Save", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        @status_label = FXLabel.new(ctrl_frame, "Unsaved", :opts => LAYOUT_CENTER_Y)

        @save_btn.connect(SEL_COMMAND) {save_sequence}
        @load_btn.connect(SEL_COMMAND) {load_sequence}

        splitter = FXSplitter.new(main_frame, LAYOUT_FILL_X | SPLITTER_HORIZONTAL | LAYOUT_FILL_Y | SPLITTER_TRACKING)

        left_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FIX_WIDTH | LAYOUT_FILL_Y, :width => 400, :padding => 0)
        seq_ctrl_frame = FXHorizontalFrame.new(left_frame, :opts => LAYOUT_FILL_X | FRAME_GROOVE, :padding => 0)

        @add_btn = FXButton.new(seq_ctrl_frame, "Add", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        @add_btn.connect(SEL_COMMAND) {add_sample}
        del_btn = FXButton.new(seq_ctrl_frame, "Delete", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        up_btn = FXButton.new(seq_ctrl_frame, "Up", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
        down_btn = FXButton.new(seq_ctrl_frame, "Down", nil, nil, 0, FRAME_RAISED | FRAME_THICK)

        table_frame = FXHorizontalFrame.new(left_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :height => 500, :padding => 0)
        @seqTable = FXTable.new(table_frame, :opts => TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_SIDE_TOP, :padding => 0)
        @seqTable.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
          # we need this dummy handler here, otherwise app will crash if columnHeader is clicked
          # but table has no rows.
        end

        @seqTable.connect(SEL_COMMAND) do |sender, sel, item|
          begin
            row = item.row
            row_selected(row)
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        @seqTable.connect(SEL_CHANGED) do |sender, sel, item|
         # puts 'SEL_CHANGED'
          begin
            row = item.row
            row_selected(row)
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end

        @seqTable.connect(SEL_REPLACED) do |sender, sel, item|
        #  puts 'SEL_REPLACED'
          row = item.to.row
          apply_table
          row_selected(row)
        end


        right_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FIX_WIDTH | LAYOUT_FILL_Y, :width => 400, :padding => 0)


        tab_frame = FXVerticalFrame.new(right_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE, :height => 500)
        request_info_frame = FXHorizontalFrame.new(tab_frame, :opts => LAYOUT_FILL_X | FRAME_GROOVE, :height => 500)
        @element_label = FXLabel.new(request_info_frame, "Selected Element: N/A", :opts => LAYOUT_CENTER_Y)

        @tabBook = FXTabBook.new(tab_frame, nil, 0, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_RIGHT)

        ftab = FXTabItem.new(@tabBook, "Request", nil)
        #ftab.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))
        request_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FIX_WIDTH | LAYOUT_FILL_Y | FRAME_RAISED, :width => 100)

        editor_frame = FXVerticalFrame.new(request_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
        @request_editor = Watobo::Gui::RequestEditor.new(editor_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)

        #        frame = FXVerticalFrame.new(tab_frame, :opts => LAYOUT_FILL_Y | LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0)

        stab = FXTabItem.new(@tabBook, "Handler", nil)
        #       stab.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))
        frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
        tab_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE)
        frame = FXHorizontalFrame.new(tab_frame, :opts => LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "lambda{|response|").setFont(FXFont.new(getApp(), "helvetica", 9, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))

        @handler_editor = Watobo::Gui::RequestEditor.new(tab_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
        frame = FXHorizontalFrame.new(tab_frame, :opts => LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "}").setFont(FXFont.new(getApp(), "helvetica", 9, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))

        #frame = FXVerticalFrame.new(tab_frame, :opts => LAYOUT_FILL_Y | LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0)
        #@sites_tree = Watobo::Gui::SitesTree.new(frame, self, nil)

        ftab = FXTabItem.new(@tabBook, "Logs", nil)
        #ftab.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTENCODING_DEFAULT))
        tab_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FIX_WIDTH | LAYOUT_FILL_Y | FRAME_RAISED, :width => 100)
        @log_viewer_frame = LogViewerFrame.new(tab_frame, :opts => LAYOUT_FILL_Y | LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0)


        initSeqTable

        update_title

      end

      private

      def initSeqTable
        @seqTable.clearItems(false)
        @seqTable.setTableSize(0, 2)

        @seqTable.rowHeader.width = 35
        @seqTable.setColumnWidth(0, 100)
        @seqTable.setColumnWidth(1, 200)

        @seqTable.setColumnText(0, "Name")
        @seqTable.setColumnText(1, "Description")


      end

      def save_sequence
        apply_tabBook(@active_element)
        apply_table

        begin
          # puts @project.settings[:session_path]
          # path = @project.settings[:session_path]+"/"
          filename = FXFileDialog.getSaveFilename(self, "Save file", @@save_dir, "All Files (*)")
          unless filename.empty?
            File.open(filename, "w") {|fh|
              fh.puts settings.to_json
            }
            @@save_dir = File.dirname(filename + '/*')
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def load_sequence
        begin
          # puts @project.settings[:session_path]
          # path = @project.settings[:session_path]+"/"
          filename = FXFileDialog.getSaveFilename(self, "Save file", @@save_dir, "All Files (*)")
          unless filename.empty?
            s = JSON.parse File.read(filename)
            puts s
            @sequence = s['sequence'].map {|e| OpenStruct.new e.to_h}
            @seq_name_dt.value = s['name']

            update_title

            refresh_table

            @@save_dir = File.dirname(filename + '/*')
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def run_sequence
        prefs = Watobo::Conf::Scanner.to_h
        session = Watobo::Session.new(Time.now.to_i, prefs)

        @sequence.each do |s|
          puts "Sequence ##{s.index}"
          next if s.request.strip.empty?

          s.request.extend Watobo::Mixins::RequestParser
          test_request = s.request.to_request
          puts test_request

          request, response = session.doRequest(test_request, prefs)

          # run response handler
          unless s.handler.strip.empty?
            handler = create_handler(s.handler)
            handler.call(response)
          end

          if @logChat.checked? == true
            chat = Watobo::Chat.new(request, response, :source => CHAT_SOURCE_MANUAL, :run_passive_checks => false)
            Watobo::Chats.add(chat)
          end
        end

      end

      def update_title
        self.title = 'Sequencer: ' + @seq_name_dt.value
      end

      def row_selected(row)
        # apply tabBook to active element
        apply_tabBook(@active_element)

        # set selected row as active element
        @active_element = @sequence[row]
        @element_label.text = 'Selected Element: ' + @active_element.name

        # update tabBook
        update_tabBook(@active_element)
        #  @seqTable.selectRow(row, false)
      end

      def add_sample
        index = @seqTable.numRows
        @sequence << OpenStruct.new(:index => index,
                                    :name => "Unnamed #{index}",
                                    :description => '',
                                    :request => '',
                                    :handler => ''
        )


        @seqTable.appendRows(1)

        # self.rowHeader.setItemJustify(lastRowIndex, FXHeaderItem::RIGHT)
        @seqTable.setRowText(index, index.to_s)
        @seqTable.setItemText(index, 0, @sequence.last.name)
        @seqTable.setItemText(index, 1, @sequence.last.description)

        @active_element = @sequence.last
        update_tabBook(@active_element)

      end

      def refresh_table
        initSeqTable

        @sequence.sort_by {|s| s.index}.each do |seq|
          index = @seqTable.getNumRows
          @seqTable.appendRows(1)

          @seqTable.setRowText(index, index.to_s)
          @seqTable.setItemText(index, 0, seq.name)
          @seqTable.setItemText(index, 1, seq.description)

        end
      end

      def update_tabBook(element)
        @request_editor.textbox.text = element.request
        @handler_editor.textbox.text = element.handler
      end

      # applies current tabBook settings to the given element
      def apply_tabBook(element)
        unless element.nil?
          element.request = @request_editor.textbox.text
          element.handler = @handler_editor.textbox.text
        end
      end

      # applies table text entries to sequence elements
      def apply_table
        @seqTable.numRows.times do |i|
          @sequence[i].name = @seqTable.getItemText(i, 0)
          @sequence[i].description = @seqTable.getItemText(i, 1)
        end
      end

      def create_handler(code)
        code_str = ['lambda{|response|']
        code_str << code
        code_str << '}'
        eval code_str.join("\n")
      end

    end
  end
end