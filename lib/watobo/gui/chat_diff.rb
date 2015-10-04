# @private 
module Watobo#:nodoc: all
  module Gui
    DIFF_TYPE_ORIG = 0
    DIFF_TYPE_NEW = 1
    
    include Diff::LCS
    
    class ChatDiffFrame < FXVerticalFrame
      
      def textWidth=(cols)
        @textWidth = cols
        @dataText.wrapColumns = cols
        
      end
      
      def textWidth
        @textWidth
      end
      
      def highlightChanges(textWidget, text, diff_blocks)
        
      end
      
      
      def makeRowVisible(row)
        dummy = @dataText.to_s
        dummy = dummy.unpack("C*").pack("C*")
        data_rows = dummy.split("\n")
        if row > 0 then
          pos = data_rows.slice(0..row-1).join("\n").length+1
        else
          pos = 0
        end
        @dataText.makePositionVisible(@dataText.to_s.length)
        @dataText.makePositionVisible(pos)
      end
      
      def showDiff(data, diff_blocks)
        data_pos = 0
        diff_pos = 0
        @dataText.setText('')
        
        begin
          if diff_blocks.length > 0 then
            data.each do |d|
              if diff_blocks[diff_pos].position == data_pos then
                @dataText.appendStyledText(data[data_pos]+"\n", @style)
                diff_pos += 1
              else
                @dataText.appendText(data[data_pos]+"\n")
              end
              data_pos += 1
              break if diff_pos >= diff_blocks.length
            end
          end
          
          while data_pos < data.length
            @dataText.appendText(data[data_pos]+"\n")
            data_pos += 1
          end
        rescue => bang
          puts bang
        end
      end
      
      
      def initialize(owner, opts)
        @textWidth = 80
        @diffType = DIFF_TYPE_ORIG
        @style = 1
        
        super(owner, :opts => opts[:opts])
        
        @textWidth = opts[:textWidth] if opts[:textWidth]
        @diffType = opts[:diffType] if opts[:diffType]
        @style = 2 if @diffType == DIFF_TYPE_NEW
        #text_opts = LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_FIXEDWRAP|TEXT_WORDWRAP|FRAME_SUNKEN
        text_opts = LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN
        
        hs_green = FXHiliteStyle.new
        hs_green.normalForeColor = FXRGBA(255,255,255,255) 
        hs_green.normalBackColor = FXRGBA(0,255,0,1)   
        hs_green.style = FXText::STYLE_BOLD
        
        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,255,255,255) 
        hs_red.normalBackColor = FXRGBA(255,0,0,1)   
        hs_red.style = FXText::STYLE_BOLD
        
        
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|FRAME_THICK, :padding => 0)
        data_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @dataText = FXText.new(data_frame, :opts => text_opts)
        @dataText.styled = true
        @dataText.hiliteStyles = [ hs_red, hs_green]
        @dataText.wrapColumns = @textWidth
        @dataText.visibleColumns = @textWidth
        @dataText.editable = false
        
        
      end
    end
    
    class ChatDiffViewer < FXDialogBox
      
      include Watobo::Gui::Icons
      
      def onTableClick(sender,sel,item)    
        row = item.row
        action = sender.getItem(row, 0).text.to_s
        pos = sender.getItem(row, 1).text.to_i
        
        sender.killSelection()
        if action == "+" then
          @diff_new.makeRowVisible(pos)
        else
          @diff_orig.makeRowVisible(pos)
        end
      end
      
      def adjustLine(line)    
        result = []
        line.strip!
        if line.length > 0 then                    
          pos = 0
          while pos < line.length
            result.push line[pos..pos+@max_line_length-1]
            pos += @max_line_length
          end   
        end
        return result
      end
      
      def updateBlocks(data_old, data_new, blocks, diffs)
        ib = []
        rb = []
        context_lines = 3
        file_length_difference = 0
        
        diffs.each do |piece|
          hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, context_lines, file_length_difference)
          hunk.blocks.each do |b|
            ib.concat b.insert
            rb.concat b.remove
          end
        end
        blocks[:remove] = rb
        blocks[:insert] = ib
      end
      
      
      def normalizeData(data)
        raise ArgumentError, "Bad data type. Need Request/Response." unless data.respond_to? :headers 
        dummy = []
        begin
          unless data.headers.nil?
            data.headers.each do |h|
              dummy.concat adjustLine(h)    
            end
            
            dummy.push ""
          end
          
          
          unless data.body.nil?
          #  puts "> clean up body #{data.body.length}"
            body =  data.body_encoded
            body.split("\n").each do |l|
             # puts "[#{i}] #{l}"
              dummy.concat adjustLine(l)
            end
          end
        rescue => bang
          puts bang
          dummy = data
        end
        #  puts dummy.join("\n")
       # return dummy.join("\n")
        return dummy
      end
      
      
      def getInserts(data_old, data_new)
        
        
        return nil if diffs.empty?
        
      end
      
      def showRequestDiff()
        @diff_orig.showDiff(@normRequestOrig, @requestBlocks[:remove])
        @diff_new.showDiff(@normRequestNew, @requestBlocks[:insert])
        
      end
      
      def showResponseDiff()
        @diff_orig.showDiff(@normResponseOrig, @responseBlocks[:remove])
        @diff_new.showDiff(@normResponseNew, @responseBlocks[:insert])
      end
      
      def initNavTable(table)
        table.clearItems()
        table.setTableSize(0, 3)
        
        table.setColumnText( 0, "Type" ) 
        table.setColumnText( 1, "Pos" )
        table.setColumnText( 2, "Count" )
        
        table.rowHeader.width = 0
        table.setColumnWidth(0, 50)
        table.setColumnWidth(1, 50)
        table.setColumnWidth(2, 50)
      end
      
      def updateNavTables()
        req_collection = diffCollections(@normRequestOrig, @normRequestNew, @requestDiffs)
        res_collection = diffCollections(@normResponseOrig, @normResponseNew, @responseDiffs)
        initNavTable(@navRequestTable)
        initNavTable(@navResponseTable)
        
        req_collection.each do |action, pos, count|
          lastRowIndex = @navRequestTable.getNumRows
          @navRequestTable.appendRows(1)
          
          @navRequestTable.setItemText(lastRowIndex, 0, action)
          @navRequestTable.setItemText(lastRowIndex, 1, pos.to_s)
          @navRequestTable.setItemText(lastRowIndex, 2, count.to_s)
          
        end
        
        res_collection.each do |action, pos, count|
          lastRowIndex = @navResponseTable.getNumRows
          @navResponseTable.appendRows(1)
          
          @navResponseTable.setItemText(lastRowIndex, 0, action)
          @navResponseTable.setItemText(lastRowIndex, 1, pos.to_s)
          @navResponseTable.setItemText(lastRowIndex, 2, count.to_s)
          #@navRequestTable.getItem(lastRowIndex, index).justify = FXTableItem::LEFT
          
        end
      end
      
      def diffCollections(data_old, data_new, diffs)
        file_length_difference = 0
        context_lines = 3
        raw_chunks = []
        collections = []
                
        return collections if diffs.empty?
        oldhunk = hunk = nil
        file_length_difference = 0
        diffs.each do |piece|
          begin
            hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, context_lines, file_length_difference)
            file_length_difference = hunk.file_length_difference
            next unless oldhunk
            if (context_lines > 0 ) and hunk.overlaps?(oldhunk)
              hunk.unshift(oldhunk)
            else
              raw_chunks.concat oldhunk.blocks
            end
          ensure
            oldhunk = hunk
          end
        end
        raw_chunks.concat oldhunk.blocks
        
        
        raw_chunks.each do |block|
          begin
            
            last_pos = -1
            last_action = '+'
            count = 0            
            block.insert.each do |b|
              if last_pos < 0 then
                last_pos = b.position
                count = 0
              elsif b.position-1 == (last_pos + count) then
                count +=1                
              else
                collections.push [last_action, last_pos, count+1 ]
                last_pos = b.position
                count = 0
              end
            end
            
            collections.push [ last_action, last_pos, count+1 ] if block.insert.length > 0
            
          rescue => bang
            puts bang            
          end
        end
        
        raw_chunks.each do |block|
          begin
            
            last_pos = -1
            last_action = '-'
            count = 0            
            
            block.remove.each do |b|
              if last_pos < 0 then
                last_pos = b.position
                count = 0
              elsif b.position-1 == (last_pos + count) then
                count +=1                
              else
                collections.push [last_action, last_pos, count+1 ]
                last_pos = b.position
                count = 0
              end
            end
            
            collections.push [ last_action, last_pos, count+1 ] if block.remove.length > 0
            
            
          rescue => bang
            puts bang            
          end
        end
        
        return collections.sort_by{ |e| e[1]}
      end
      
      
      def initialize(owner, chat_orig, chat_new)
        # Invoke base class initialize function first
        super(owner, "Chat Differ", :opts => DECOR_ALL,:width=>800, :height=>600)
        self.icon = ICON_DIFFER
        @chat_orig = chat_orig
        @chat_new = chat_new
        @max_line_length = 80
        
        @requestBlocks = Hash.new
        @responseBlocks = Hash.new
        
        main = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        left = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH, :width => 200, :padding => 0)
        
        @tabBook = FXTabBook.new(left, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        res_tab = FXTabItem.new(@tabBook, "Response", nil)
        res_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|FRAME_THICK)
        sunken = FXVerticalFrame.new(res_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @navResponseTable = FXTable.new(sunken, :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        @navResponseTable.connect(SEL_COMMAND, method(:onTableClick))
        
        req_tab = FXTabItem.new(@tabBook, "Request", nil)
        req_frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        sunken = FXVerticalFrame.new(req_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
        @navRequestTable = FXTable.new(sunken, :opts => FRAME_SUNKEN|TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        
        
        orig_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X, :padding => 0)
        frame = FXVerticalFrame.new(orig_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Original")
        
        @diff_orig = ChatDiffFrame.new(orig_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :diffType => DIFF_TYPE_ORIG)
        
        new_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X, :padding => 0)
        frame = FXVerticalFrame.new(new_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "New")
        
        
        @diff_new = ChatDiffFrame.new(new_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :diffType => DIFF_TYPE_NEW)
        
        
        
        @tabBook.connect(SEL_COMMAND) {
          if @tabBook.current == 0 then
            showResponseDiff()
          else
            showRequestDiff()
          end
        }
        # normalize data before processing
        # * remove empty lines, binary data
        # * wrap lines after @max_line_length
        @normRequestOrig = normalizeData(chat_orig.request)
        @normResponseOrig = normalizeData(chat_orig.response)
        
        @normRequestNew = normalizeData(chat_new.request)
        @normResponseNew = normalizeData(chat_new.response)
        
             
        # diff normalized data
        @requestDiffs = Diff::LCS.diff( @normRequestOrig, @normRequestNew )
        @responseDiffs = Diff::LCS.diff( @normResponseOrig, @normResponseNew )
        
        # set diff blocks
        updateBlocks(@normRequestOrig, @normRequestNew, @requestBlocks, @requestDiffs)
        updateBlocks(@normResponseOrig, @normResponseNew, @responseBlocks, @responseDiffs)
        
        updateNavTables()
        
        showResponseDiff()
        
        
        
      end
    end
  end
end
