# @private
module Watobo #:nodoc: all
  module Gui
    class LogViewerFrame < FXVerticalFrame

      attr :scan_chats

      include Watobo::Subscriber

      def reload
        initScanTable
        Watobo::DataStore.scans.sort_by {|f| File.ctime(f).to_i}.each do |file|
          lastRowIndex = @scanTable.getNumRows
          @scanTable.appendRows(1)
          @scanTable.setItemText(lastRowIndex, 0, File.basename(file))
          @scanTable.setItemData(lastRowIndex, 0, file)
          @scanTable.setItemText(lastRowIndex, 1, File.ctime(file).strftime("%F/%T"))


        end
      end

      def initialize(owner, prefs)
        super(owner, prefs)

        @scan_chats = []
        FXLabel.new(self, "Scan-Logs")

        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_GROOVE, :padding => 0)

        @scanTable = FXTable.new(frame, :opts => FRAME_SUNKEN | TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP, :padding => 2)

        @scanTable.connect(SEL_COMMAND) do |sender, sel, item|
          row = item.row
          @scanTable.selectRow(row, false)
          scan_name = @scanTable.getItemText(row, 0)

          @scan_chats = Watobo::DataStore.load_scan(scan_name)

          notify(:show_chats, @scan_chats)
        end

        initScanTable

      end

      private

      def initScanTable
        @scanTable.clearItems(false)
        @scanTable.setTableSize(0, 2)

        @scanTable.setColumnText(0, "Name")
        @scanTable.setColumnText(1, "Date")
        #@scanTable.setColumnText(2, "Duration")
        #@scanTable.setColumnText(3, "Checksum")

        @scanTable.rowHeader.width = 0
        @scanTable.setColumnWidth(0, 100)

        @scanTable.setColumnWidth(1, 200)
        #@scanTable.setColumnWidth(2, 80)
        #@scanTable.setColumnWidth(3, 300)

      end


    end

  end
end

