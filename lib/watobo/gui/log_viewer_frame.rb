# @private
module Watobo #:nodoc: all
  module Gui
    class LogViewerFrame < FXVerticalFrame

      attr :scan_chats

      include Watobo::Subscriber

      def reload
        initScanTable
        # return false unless Watobo::DataStore.respond_to?( :scans )
        Watobo::DataStore.scans.sort_by {|f| File.ctime(f).to_i}.each do |file|
          lastRowIndex = @scanTable.getNumRows
          @scanTable.appendRows(1)
          @scanTable.setItemText(lastRowIndex, 0, File.basename(file))
          @scanTable.setItemData(lastRowIndex, 0, file)
          @scanTable.setItemText(lastRowIndex, 1, File.ctime(file).strftime("%T %F"))
          2.times do |i|
            item = @scanTable.getItem(lastRowIndex, i)
            item.justify = FXTableItem::LEFT unless item.nil?
            @scanTable.fitColumnsToContents(i)
          end

        end
      end

      def initialize(owner, prefs)
        super(owner, prefs)

        @scan_chats = []

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | FRAME_SUNKEN) #| FRAME_GROOVE)
        FXLabel.new(frame, "Scan-Logs")

        # @refresh_btn = FXButton.new(frame, "\tNew Project\tNew Project.", :icon => ICON_ADD_PROJECT, :padding => 0)
        @refresh_btn = FXButton.new(frame, "refresh", :opts => BUTTON_NORMAL | LAYOUT_RIGHT)
        @refresh_btn.connect(SEL_COMMAND) {reload}

        @scanTable = FXTable.new(self, :opts => TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)

        @scanTable.connect(SEL_COMMAND) do |sender, sel, item|
          begin
            row = item.row
            @scanTable.selectRow(row, false)
            scan_name = @scanTable.getItemText(row, 0)

            getApp().beginWaitCursor()
            @scan_chats = Watobo::DataStore.load_scan(scan_name)

            notify(:show_chats, @scan_chats)
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          ensure
            getApp().endWaitCursor()
          end

        end
        initScanTable
      end

      private

      def initScanTable
        @scanTable.clearItems(false)
        @scanTable.setTableSize(0, 2)

        @scanTable.setColumnText(0, "Name")
        @scanTable.setColumnText(1, "Date")

        @scanTable.rowHeader.width = 0
        @scanTable.setColumnWidth(0, 100)

        @scanTable.setColumnWidth(1, 200)

      end


    end

  end
end

