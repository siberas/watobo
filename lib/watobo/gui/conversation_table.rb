class CustomTableItem < FXTableItem
  attr_accessor :color
  attr_accessor :backcolor
  def drawContent table, unusable_dc, x, y, w, h
    FXDCWindow.new(table) {|dc|
      if @color and not selected?

        if @backcolor
        dc.foreground = @backcolor
        hg = table.horizontalGridShown? ? 1 : 0
        vg = table.verticalGridShown? ? 1 : 0
        dc.fillRectangle(x + vg, y + hg, w - vg, h - hg)
        end

        dc.foreground = @color

        def dc.setForeground color
          1 # stop super from setting color back
        end
      end

      dc.setFont unusable_dc.getFont
      super table, dc, x, y, w, h
    }
  end
end

class FXColoredTable < FXTable
  def createItem *parameters
    CustomTableItem.new(*parameters)
  end

  def setItemTextColor row, column, color
    getItem(row, column).color = color
    updateItem row, column
  end

  def setCellBackground row, column, color
    getItem(row, column).backcolor = color
  # puts getItem(row, column).methods.sort
  #  updateItem row, column
  end
end

# @private 
module Watobo#:nodoc: all
  module Gui
    TABLE_COL_METHOD = 0x0001
    TABLE_COL_HOST = 0x0002
    TABLE_COL_PATH = 0x0004
    TABLE_COL_PARMS = 0x0008
    TABLE_COL_STATUS = 0x0010
    TABLE_COL_COOKIE = 0x0020
    TABLE_COL_COMMENT = 0x0040
    TABLE_COL_SSL = 0x0100
    class ConversationTable < FXTable
      #    class ConversationTable < FXColoredTable
      
      attr :filter

      attr_accessor :autoscroll
      attr_accessor :url_decode

      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listeners[event] ||= []
        @event_dispatcher_listeners[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          #  puts "NOTIFY: #{self}(:#{event}) [#{@event_dispatcher_listeners[event].length}]" if $DEBUG
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def num_total
        @current_chat_list.length
      end

      def num_visible
        self.numRows
      end

    
      def apply_filter(filter={})
        @filter = filter      
        puts @filter.to_yaml if $DEBUG
        update_table
      end

      def current_chat
        # puts currentRow
        if currentRow >= 0
          chatid = getRowText(currentRow).to_i
          chat = Watobo::Chats.get_by_id(chatid)
        return chat
        end
        return nil
      end

      def chat_visible?(chat)
        begin
          return false if @filter[:ok_only] == true and chat.response.responseCode !~ /200/ 
           
          if @filter[:unique]
            unless Watobo::Gui.project.nil?
              uniq_hash = Watobo::Gui.project.uniqueRequestHash chat.request
              return false if @uniq_chats.has_key? uniq_hash
              @uniq_chats[uniq_hash] = nil
            end
          end

          if @filter[:show_scope_only]
            unless Watobo::Gui.project.nil?
              return false unless Watobo::Scope.match_site?(chat.request.site)
            end
          end
          # puts "* passed scope"
          if @filter[:hide_tested]
          return false if chat.tested?
          end
          # puts "* passed hide tested"
          unless @filter[:doc_filter].include?(chat.request.doctype)
            return true if @filter[:text].empty?

            return true if @filter[:url] == true and chat.request.first =~ /#{@filter[:text]}/i

            return true if @filter[:request] == true and chat.request.join =~ /#{@filter[:text]}/i
            # puts @filter.to_yaml
            # puts chat.response.responseCode

            if @filter[:response] == true 
              return false if @filter[:text_only] == true and chat.response.content_type !~ /(text|javascript|xml|json)/ 
              return true if chat.response.join.unpack("C*").pack("C*") =~ /#{@filter[:text]}/i
            end

          end
        rescue => bang
          puts "! could not add chat to table !".upcase
          #  puts chat.id
          puts bang
          puts bang.backtrace if $DEBUG
        end
        false
      end

      def showConversation( chat_list = nil, prefs = {} )
        clearConversation()
        if chat_list.nil?
          Watobo::Chats.each do |chat|
            addChat(chat, prefs)
          end
        else
          chat_list.each do |chat|
            addChat(chat, prefs)
          end
        end
        adjustCellWidth()
      end

      def setNewFont(font_type=nil, size=nil)
        begin
          new_size = size.nil? ? GUI_REGULAR_FONT_SIZE : size
          new_font_type = font_type.nil? ? "helvetica" : font_type
          new_font = FXFont.new(getApp(), new_font_type, new_size)
          new_font.create

          self.font = new_font
          self.rowHeader.font = new_font
          self.defRowHeight = new_size+10

          update_table()

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def updateComment(row, comment)
        col = @col_order.index(TABLE_COL_COMMENT)
        self.setItemText(row, col, comment.gsub(/[^[:print:]]/,' '))
      end

      def addChat(chat, *prefs)
        return false if chat.nil?
        if self.getNumRows <= 0 then
          clearConversation()
        # initColumns()
        end

        @current_chat_list.push chat 
        if prefs.include? :ignore_filter
          add_chat_row(chat)
        return true
        end
        add_chat_row(chat) if Chats.match?(chat, @filter)
        return true

      end

      def initColumns()
        self.setTableSize(0, @columns.length)
        self.visibleRows = 20
        self.visibleColumns = @columns.length

        @columns.each do |type, name|
          index = @col_order.index(type)
          self.setColumnText( index, name )
          self.setColumnIcon(@col_order.index(TABLE_COL_SSL), TBL_ICON_LOCK)# puts self.getItem(@col_order.index(col), 0  ).class.to_s
        end

      end

      def initialize( owner, unused = nil )
        @event_dispatcher_listeners = Hash.new

        super(owner, :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP, :padding => 2)
        
         @filter = {}

        @url_decode = true

        self.setBackColor(FXRGB(255, 255, 255))
        self.setCellColor(0, 0, FXRGB(255, 255, 255))
        self.setCellColor(0, 1, FXRGB(255, 240, 240))
        self.setCellColor(1, 0, FXRGB(240, 255, 240))
        self.setCellColor(1, 1, FXRGB(240, 240, 255))

      #  reset_filter
        #   FXMAPFUNC(SEL_CLICKED, FXTable::ID_SELECT_CELL, :onSelectCell)
        @current_chat_list = []
        @uniq_chats = Hash.new

        @columns = Hash.new
        @cell_width = Hash.new
        @col_order = []
        @autoscroll = false

        @columns = Hash.new

        @columns[TABLE_COL_METHOD] = "Method"
        @columns[TABLE_COL_HOST] = "Host"
        @columns[TABLE_COL_PATH] = "Path"
        @columns[TABLE_COL_PARMS] = "Parameters"
        @columns[TABLE_COL_STATUS] = "Status"
        @columns[TABLE_COL_COOKIE] = "Set-Cookie"
        @columns[TABLE_COL_COMMENT] = "Comment"
        @columns[TABLE_COL_SSL] = ""

        # initialize columns order
        @col_order = [ TABLE_COL_SSL, TABLE_COL_METHOD, TABLE_COL_HOST, TABLE_COL_PATH, TABLE_COL_PARMS, TABLE_COL_STATUS, TABLE_COL_COOKIE, TABLE_COL_COMMENT ]

        # init cell width
        @cell_width = Hash.new
        @cell_width[TABLE_COL_METHOD] = 50
        @cell_width[TABLE_COL_HOST] = 120
        @cell_width[TABLE_COL_PATH] = 200
        @cell_width[TABLE_COL_PARMS] = 150
        @cell_width[TABLE_COL_STATUS] = 50
        @cell_width[TABLE_COL_COOKIE] = 70
        @cell_width[TABLE_COL_COMMENT] = 100
        @cell_width[TABLE_COL_SSL] = 20

        @cell_width_defaults = Hash.new
        @cell_width_defaults.update YAML.load(YAML.dump(@cell_width))

        @cell_auto_max = 400
        @cell_min_width = 30

        initColumns()

        self.columnHeader.connect(SEL_CHANGED) do |sender, sel, index|
          type = @col_order[index]
          @cell_width[type] = self.getColumnWidth(index)
        end

        self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
          type = @col_order[index]
          column_width = self.getColumnWidth(index)

          new_width = case column_width
          when column_width > @cell_auto_max
            @cell_auto_max
          when ( column_width > @cell_width_defaults[type] )
            @cell_width_defaults[type]
          when @cell_width_defaults[type]
            self.fitColumnsToContents(index)
            w = self.getColumnWidth(index)
            w = @cell_auto_max if self.getColumnWidth(index) > @cell_auto_max
            w = @cell_width_defaults[type] if self.getColumnWidth(index) < @cell_width_defaults[type]
            w
          else
          @cell_width_defaults[type]
          end
          self.setColumnWidth(index, new_width)
          @cell_width[type] = new_width
          self.rowHeaderMode = 0

          adjustCellWidth()
          
          
        end
        
        self.connect(SEL_CHANGED){ |sender, sel, item|
         # puts "SEL_CHANGED #{item.row}"
          self.selectRow(item.row, false)
           chat = self.getItemData(item.row, 0)
           notify(:chat_selected, chat) if chat.respond_to? :request
        }
        
        self.connect(SEL_COMMAND){ |sender, sel, item|
         # puts "SEL_COMMAND #{item.row}"
          self.selectRow(item.row, false)
           chat = self.getItemData(item.row, 0)
           notify(:chat_selected, chat) if chat.respond_to? :request
        }
        
        self.connect(SEL_DOUBLECLICKED){ |sender, sel, item|
          #   puts "SEL_DOUBLECLICKED #{item.row}"
          self.selectRow(item.row, false)
           chat = self.getItemData(item.row, 0)
           notify(:chat_doubleclicked, chat) if chat.respond_to? :request
        }
        
        self.connect(SEL_SELECTED){ |sender, sel, item|
           #  puts "SEL_SELECTED #{item.row}"
          self.selectRow(item.row, false)
           chat = self.getItemData(item.row, 0)
           notify(:chat_selected, chat) if chat.respond_to? :request
        }

        adjustCellWidth()

        addHotkeyHandler(self)
        
        start_update_timer
      end

      def scrollUp()
        #self.makePositionVisible(0, 0)
         self.setPosition(self.xPosition, 0)
      end

      def scrollDown()
        #self.makePositionVisible(self.numRows-1, 0)
        #puts "[scrollDown] >>"
        #puts "xPos: #{self.xPosition}"
        #puts "yPos: #{self.yPosition}"
        #puts "viewportHeight: #{self.viewportHeight}"
        #puts "contentHeight: #{self.contentHeight}"
        #puts "y-diff: #{self.viewportHeight - self.contentHeight}"
        #puts "---"
         self.setPosition(self.xPosition, (self.viewportHeight - self.contentHeight))
      end
      
      def start_update_timer
        @last_row_count = 0
        @timer = FXApp.instance.addTimeout( 150, :repeat => true) {
          if self.getNumRows != @last_row_count
             scrollDown if @autoscroll == true
             @last_row_count = self.getNumRows
          end
          }

      end

      def clearConversation()
        self.clearItems
        @current_chat_list = []
        initColumns()
        adjustCellWidth()
      end

      private

      def add_chat_row(chat)
        return false unless chat.respond_to? :request
        return false unless chat.respond_to? :response 
        return false if chat.request.nil?
        return false if chat.response.nil?
        
        lastRowIndex = self.getNumRows
        self.appendRows(1)

        self.rowHeader.setItemJustify(lastRowIndex, FXHeaderItem::RIGHT)
        self.setRowText(lastRowIndex, chat.id.to_s)

        index = @col_order.index(TABLE_COL_SSL)
        self.setItemIcon(lastRowIndex, index, TBL_ICON_LOCK) if chat.request.is_ssl?

        index = @col_order.index(TABLE_COL_METHOD)

        self.setItemText(lastRowIndex, index, chat.request.method)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_HOST)
        self.setItemText(lastRowIndex, index, chat.request.host)
        self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_PATH)
        self.setItemText(lastRowIndex, index, chat.request.path)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_PARMS)
        ps = ""
        rup = chat.request.urlparms
        unless rup.nil?
        ps << rup
        end        

        if chat.request.method =~ /POST/ and !chat.request.body.nil? then
            post_parms_string = ''
            post_parms_string << chat.request.body            
            ps << "&&" unless ps.empty?
            ps << post_parms_string          
        end

        ps = "*MULTIPART*" if chat.request.content_type =~ /multipart/i

        parms = ""
        unless ps.empty?
          ps_ascii = ps.force_encoding('ASCII-8BIT')
          
          if @url_decode == true
            if chat.request.content_type =~ /(json|xml)/
              parms = ps_ascii
            else              
              parms = CGI.unescape(ps_ascii)              
            end
          end
          parms.gsub!(/[^[:print:]]/,'.')

        end
        
        self.setItemText(lastRowIndex, index, parms)
        self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT

        index = @col_order.index(TABLE_COL_STATUS)
        self.setItemText(lastRowIndex, index, chat.response.status)
        self.getItem(lastRowIndex,index).justify = FXTableItem::LEFT

        if chat.response.header_value("set-cookie").first then
          index = @col_order.index(TABLE_COL_COOKIE)
          self.setItemText(lastRowIndex, index, chat.response.header_value("set-cookie").first.chomp)
          self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT
        end

        if chat.comment then
          index = @col_order.index(TABLE_COL_COMMENT)
          comment = chat.comment.split(/\n/).join(" ")
          cc = comment[0..50]
          cc += "..." if comment.length > 50
          self.setItemText(lastRowIndex, index, cc)
          self.getItem(lastRowIndex, index).justify = FXTableItem::LEFT
        end
        
        self.setItemData(lastRowIndex, 0, chat)

        #self.makePositionVisible(self.numRows-1, 0) if @autoscroll == true
        if @autoscroll == true
          self.setPosition(self.xPosition, (self.viewportHeight - self.contentHeight - 20 ))
        end
      end

      def update_table()
        self.clearItems
        initColumns()
        adjustCellWidth()
        Watobo::Chats.filtered(@filter) do |chat|
          add_chat_row(chat)
        end
      end
      
            
      def adjustCellWidth()
        begin
          self.rowHeader.width = 40
          #self.fitColumnsToContents(0)
          @cell_width.each do |col, width|
            pos = @col_order.index(col)
            self.setColumnWidth(pos, width)
          end
        rescue => bang
          puts "!!!ERROR: adjustCellWidth"
        end

      end

      def addHotkeyHandler(widget)
        @ctrl_pressed = false

        widget.connect(SEL_KEYPRESS) { |sender, sel, event|
        # puts event.code
        cont = false
          @ctrl_pressed = true if event.code == KEY_Control_L or event.code == KEY_Control_R
          #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          if event.code == KEY_Return             
           chat = current_chat 
           notify(:chat_doubleclicked, chat) if chat.respond_to? :request
          cont = true # special handling of KEY_Return, because we don't want a linebreak in textbox.
          end

          case event.code
          when KEY_F1

            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                [ "G - Goto",
                  "<ctrl-n> - Goto Next",
                  "<ctrl-N> - Goto Prev",
                  "<space>  - Edit Comment"
                ].each do |hk|
                  FXMenuCaption.new(menu_pane, hk).backColor = 'yellow'
                end

                menu_pane.create
                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end

          when KEY_space
            chat = current_chat
            notify(:edit_comment, chat) if chat
          when KEY_G
            open_goto_url_dialog
            cont = true
          end

          if @ctrl_pressed
            case event.code
            when KEY_n
              show_next
            when KEY_N
              show_prev
            when KEY_f
              notify(:open_filter_dlg)
            end
            cont = false
          end
          cont
        }

        widget.connect(SEL_KEYRELEASE) { |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R
          false
        }
      end

      def open_goto_url_dialog
        @url_pattern ||= ""
        dlg = Watobo::Gui::GotoUrlDialog.new(self, @url_pattern)
        if dlg.execute != 0 then
          @url_pattern = dlg.url_pattern
          show_nearest()
        end
        true
      end
      
      def show_next()
        i = get_next_match
        if i >= 0
        selectRow(i, false) 
         setCurrentItem(i, 2)
         makePositionVisible(i,2)
         end
      end
      
      def show_prev()
        i = get_prev_match
        if i >= 0
        selectRow(i, false) 
         setCurrentItem(i, 2)
         makePositionVisible(i,2)
         end
      end
      
      
      def show_nearest()
        sel = -1
        pi = get_prev_match()
        ni = get_next_match()
       
        sel = pi
        if ( ni >= 0 ) and ( pi >= 0 )
          sel = ( currentRow - pi ) > ( ni - currentRow ) ? ni : pi
        elsif pi >= 0
          sel = pi
        else 
          sel = ni
        end
        
        if sel >= 0
          selectRow(sel, false)       
          setCurrentItem(sel, 2)
          makePositionVisible(sel,2)        
        end
        
        false
      end
      
      
      
      def get_next_match()
        return -1 if @url_pattern.nil?
        return -1 if @url_pattern.empty?
      
        row = currentRow + 1
        match = -1
        while row < numRows
          chat = self.getItemData(row, 0)
          if chat.request.url.to_s =~ /#{@url_pattern}/i
            match = row 
            #puts chat.request.url.to_s
          end
          return match if match >= 0
          row += 1
        end
        match
      end
      
      def get_prev_match()
        return -1 if @url_pattern.nil?
        return -1 if @url_pattern.empty?
     
        row = currentRow - 1
        match = -1
        while row >= 0
          chat = self.getItemData(row, 0)
          if chat.request.url.to_s =~ /#{@url_pattern}/i
            match = row 
            #puts chat.request.url.to_s
          end
          return match if match >= 0
          row -= 1
        end
        match
      end

    end
  end
end
