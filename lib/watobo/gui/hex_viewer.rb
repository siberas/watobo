# @private 
module Watobo#:nodoc: all
  module Gui
    class HexViewer < FXHorizontalFrame
      def normalizeText(text)
        dummy = []
        begin
          text.headers.each do |h|
            dummy.push h.strip.unpack("C*").pack("C*") + "\r\n"
          end
          dummy.push "\r\n"
          dummy.push text.body.unpack("C*").pack("C*")
          dummy = dummy.join
        rescue => bang
          dummy = text
        end
        return dummy
      end
      
      def setText(tobject)
        raw_text = tobject
        
        if tobject.respond_to? :has_body?
          raw_text = ""
          #raw_text << tobject.body.to_s unless tobject.body.nil? 
          raw_text << tobject.to_s
        end
        
        
        initTable()
        
        if raw_text and not raw_text.empty? then
          raw_text = normalizeText(raw_text)
          pos = 1
          col = 0
          
          row = @hexTable.getNumRows
          
          @hexTable.appendRows(1)
          @hexTable.rowHeader.setItemJustify(row, FXTableItem::LEFT)    
          @hexTable.setRowText(row, "%0.4X" % row.to_s)
          
          while pos <= raw_text.length
            chunk = raw_text[pos-1].unpack("H2")[0]
            @hexTable.setItemText(row, col, chunk)
            @hexTable.getItem(row, col).justify = FXTableItem::LEFT
            
            if pos % 16 == 0 then
              chunk = raw_text[row*16..pos-1]
              
             
             # Filter bad utf-8 chars
              printable = chunk.unpack("C*").pack("C*").gsub(/[^[:print:]]/,'.')
              @hexTable.setItemText(row, 16, printable) if !chunk.nil?
              @hexTable.getItem(row, 16).justify = FXTableItem::LEFT
              
              row = @hexTable.getNumRows
              @hexTable.appendRows(1)
              
              # puts "=#{pos}/#{row}"
              @hexTable.rowHeader.setItemJustify(row, FXTableItem::LEFT)        
              @hexTable.setRowText(row, "%0.4X" % (row*16).to_s)
              
              col = -1
            end
            pos += 1
            col += 1 
          end
          chunk = StringIO.new
          chunk.set_encoding('ASCII-8BIT')
          #chunk = raw_text[row*16..pos-1]
          chunk << raw_text[row*16..pos-1]
          @hexTable.setItemText(row, 16, chunk.string.gsub(/[^[:print:]]/,'.')) if !chunk.nil?
          @hexTable.getItem(row, 16).justify = FXTableItem::LEFT
          
        end
        
        0.upto(16) do |i|
          @hexTable.fitColumnsToContents(i)
        end
      end
      
      def initialize(owner)
        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        sunken = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @hexTable = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        f = FXFont.new(getApp(), "courier", 8,  FONTSLANT_REGULAR, FONTENCODING_DEFAULT)
        @hexTable.font = f
        @hexTable.columnHeaderFont = f
        @hexTable.rowHeaderFont = f
        
        
      end
      
      private
      def initTable
        @hexTable.clearItems()
        @hexTable.setTableSize(0, 17)
        @hexTable.rowHeader.width = 50
        0.upto(15) do |i|       
          htext = "%X" % i
          @hexTable.setColumnText( i, htext)          
         # @hexTable.setColumnWidth(i, 33)
        end  
        @hexTable.setColumnWidth(16, 115)
      end
    end
  end
end
