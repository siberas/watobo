# @private 
module Watobo#:nodoc: all
  module Gui
    class SelectionInfo < FXVerticalFrame
      def update(info)
        begin
          @hid_label.text = info[:hid] || "-"
          @url_label.text = info[:url] || "-"
          @length_label.text = info[:length] || "-"
          @status_label.text = info[:status] || "-"

        rescue => bang
          puts "!!! Could not update SelectionInfo"
          puts bang
        end
      end

      def clear()
        @hid_label.text = "-"
        @url_label.text = "-"
        @length_label.text = "-"
        @status_label.text = "-"
      end

      def initialize(owner, opts)
        super(owner, opts)
        frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "History-ID: ")
        @hid_label = FXLabel.new(frame, " - ")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "URL: ")
        @url_label = FXLabel.new(frame, " - ")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "Length: ")
        @length_label = FXLabel.new(frame, " - ")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
        FXLabel.new(frame, "Status: ")
        @status_label = FXLabel.new(frame, " - ")
      end
    end

    class DiffFrame < FXVerticalFrame
      include Responder

      ID_HISTORY_BUTTON = FXMainWindow::ID_LAST
      def onHistoryButton(sender, sel, event)
        @history_slider.reset()
        sender.parent.backColor = FXColor::Red
        @slider_selection = sender.parent.item
      end

      def updateHistory(history)
        @slider_selection = nil
        @history = history
        # @history_slider.update(history)
        updateHistoryTable()
      # updateSelections()
      end

      def onTableClick(sender,sel,item)
        begin

          row = item.row
          @historyTable.selectRow(row, false)
          hi = @historyTable.getRowText(row).to_i - 1

          if @first_selection and @second_selection
            @first_selection = nil
            @second_selection = nil
          end

          if !@first_selection
            @first_selection = @history[hi]
          else
            @second_selection = @history[hi]
          end

          updateSelection()

        rescue => bang
          puts "!!!ERROR: onTableClick"
          puts bang
          puts "!!!"

        end
      end

      def initHistoryTable()
        @historyTable.clearItems()
        @historyTable.setTableSize(0, 3)

        @historyTable.setColumnText( 0, "STATUS" )
        @historyTable.setColumnText( 1, "LENGTH" )
        @historyTable.setColumnText( 2, "URL" )

        @historyTable.rowHeader.width = 50
        @historyTable.setColumnWidth(0, 100)

        @historyTable.setColumnWidth(1, 100)
        @historyTable.setColumnWidth(2, 200)

      end

      def updateHistoryTable()
        begin
          @historyTable.clearItems()
          initHistoryTable()

          @history.each do |h|
            lastRowIndex = @historyTable.getNumRows
            @historyTable.appendRows(1)
            @historyTable.setRowText(lastRowIndex, (@history.index(h) + 1 ).to_s)
            @historyTable.setItemText(lastRowIndex, 0, h.response.status) if h.response.respond_to? :status
            @historyTable.setItemText(lastRowIndex, 1, h.response.join.length.to_s)
            @historyTable.setItemText(lastRowIndex, 2, h.request.url.to_s) if h.request.respond_to? :url
            3.times do |i|
              i = @historyTable.getItem(lastRowIndex, i)
              i.justify = FXTableItem::LEFT unless i.nil?
            end
          end
        rescue => bang
          puts bang
        end

      end

      def updateSelection()
        @first_sel_info.clear()
        @second_sel_info.clear()

        if @first_selection

          @first_sel_info.update( :url => @first_selection.request.url.to_s,
          :hid => (@history.index(@first_selection) + 1).to_s,
          :status => @first_selection.response.status,
          :length => @first_selection.response.join.length.to_s)

        end

        if @second_selection
          @second_sel_info.update( :url => @second_selection.request.url.to_s,
          :hid => (@history.index(@second_selection) + 1).to_s,
          :status => @second_selection.response.status,
          :length => @second_selection.response.join.length.to_s)

        end
      end

      def getDiffChats()
        first = nil
        second = nil
        begin
          case @first_chat_dt.value
          when 0
            0
          when 1
            0
          end

        rescue

        return first, second
        end
      end

      def initialize(owner, opts)
        super(owner, opts)

        @history_size = 10
        @history = []
        @slider_selection = nil
        @first_selection = nil
        @second_selection = nil

        FXMAPFUNC(SEL_COMMAND, DiffFrame::ID_HISTORY_BUTTON, 'onHistoryButton')

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
        # frame_left = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH, :width => 70, :padding => 0)
        # @history_slider = HistorySlider.new(frame_left, self, @history_size, opts)

        frame_right = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        sunken = FXVerticalFrame.new(frame_right, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @historyTable = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        initHistoryTable()

        @historyTable.connect(SEL_COMMAND, method(:onTableClick))

        first_chat_gb = FXGroupBox.new(frame_right, "First Chat", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        @first_sel_info = SelectionInfo.new(first_chat_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        second_chat_gb = FXGroupBox.new(frame_right, "Second Chat", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        @second_sel_info = SelectionInfo.new(second_chat_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        diff_button = FXButton.new(frame_right, "Diff it!", nil, nil, 0, :opts => LAYOUT_FILL_X|FRAME_RAISED|FRAME_THICK)

        diff_button.connect(SEL_COMMAND) {
        # new, orig = getDiffChats()
          if @first_selection and @second_selection then
            first_request = Watobo::Utils.copyObject(@first_selection.request)
            first_response = Watobo::Utils.copyObject(@first_selection.response)
            second_request = Watobo::Utils.copyObject(@second_selection.request)
            second_response = Watobo::Utils.copyObject(@second_selection.response)

            chat_one = Watobo::Chat.new(first_request, first_response, :id => 0)
            chat_two = Watobo::Chat.new(second_request, second_response, :id => 0)
            project = nil
            diffViewer = ChatDiffViewer.new(FXApp.instance, chat_one, chat_two)
            diffViewer.create
            diffViewer.show(Fox::PLACEMENT_SCREEN)
          end
        }
      end
    end
  end
end