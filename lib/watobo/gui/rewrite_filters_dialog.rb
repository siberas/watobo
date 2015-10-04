# @private 
module Watobo#:nodoc: all
  module Gui
    class FilterTableCtrl < FXHorizontalFrame
      attr_accessor :target
      
      def initialize(owner,target = nil, opts)
        @target = target
        super owner, opts
        matrix = FXMatrix.new(self, 4, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        %w( Location Match Pattern Flags ).each do |l|
          FXLabel.new(matrix, l)
        end
        
        @locations_combo = FXComboBox.new(matrix, 10, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK)
        #@filterCombo.width =200

        @locations_combo.numVisible = 0
        @locations_combo.numColumns = 10
        @locations_combo.editable = false
        @locations_combo.connect(SEL_COMMAND){}
       
        @match_type_combo = FXComboBox.new(matrix, 10, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK)
        #@filterCombo.width =200

        @match_type_combo.numVisible = 0
        @match_type_combo.numColumns = 10
        @match_type_combo.editable = false
        @match_type_combo.connect(SEL_COMMAND){}
        
        @pattern_txt = FXTextField.new(matrix, 20, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
                 
        @flags_combo = FXComboBox.new(matrix, 10, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK)
        #@filterCombo.width =200

        @flags_combo.numVisible = 0
        @flags_combo.numColumns = 10
        @flags_combo.editable = false
        @flags_combo.connect(SEL_COMMAND){}
         
         frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
         top_btn_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
      
        @del_btn = FXButton.new(top_btn_frame, "Del" ,  nil, nil)
        @del_btn.enable
        @del_btn.connect(SEL_COMMAND){ delete_filter }

     #   @edit_btn = FXButton.new(top_btn_frame, "Edit ..." ,  nil, nil)
     #   @edit_btn.enable
     #   @edit_btn.connect(SEL_COMMAND){ delete_filter }

        @up_btn = FXButton.new(top_btn_frame, "Up" ,  nil, nil)
        @up_btn.enable

        @down_btn = FXButton.new(top_btn_frame, "Down" ,  nil, nil)
        @down_btn.enable
        
        add_btn_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @add_btn = FXButton.new(add_btn_frame, "Add ..." ,  nil, nil, )
        @add_btn.enable
        @add_btn.connect(SEL_COMMAND){ add_filter }

      end

      private

      def init_handlers()

      end


      def add_match_type(l)
        @match_type_combo.appendItem(l.to_s, l)
         @match_type_combo.numVisible = @match_type_combo.numItems
      end
      
      def add_location(l)
        @locations_combo.appendItem(l.to_s, l)
         @locations_combo.numVisible = @locations_combo.numItems
      end
      
      def add_flag(l)
        @flags_combo.appendItem(l.to_s, l)
         @flags_combo.numVisible = @flags_combo.numItems
      end
      
      def delete_filter
       @target.delete_current_row if @target.respond_to? :delete_current_row
        
      end
      
      def add_filter
        return false if @target.nil?
        #TODO: Add some checks if filter is ok
         location = @locations_combo.getItemData(@locations_combo.currentItem)
         pattern = @pattern_txt.text
         match_type = @match_type_combo.getItemData(@match_type_combo.currentItem)
         flag = @flags_combo.getItemData(@flags_combo.currentItem)
         
         prefs = {
           :match_type => match_type,
           :flags => ( flag != :none ) ? [flag] : []
         }
         
        filter = case location
        when :url
          Watobo::Interceptor::UrlFilter.new(pattern, prefs)
        when :method
          Watobo::Interceptor::MethodFilter.new(pattern, prefs)
        when :url_parms
          Watobo::Interceptor::HttpParmsFilter.new(pattern, prefs)
        when :status
          Watobo::Interceptor::StatusFilter.new(pattern, prefs)
        when :flags
          Watobo::Interceptor::FlagFilter.new('', prefs)
        end
         @target.add_filter filter
      end

    end
    
    class RequestFilterCtrl < FilterTableCtrl
      def initialize(owner, target, opts)
        super owner, target, opts
        add_location :url
        add_location :method
        #add_location :header
        #add_location :cookie
        add_location :url_parms
        
        add_match_type :match
        add_match_type :not_match
        
        add_flag :none
        add_flag :request
      end
    end
    
    class ResponseFilterCtrl < FilterTableCtrl
      def initialize(owner, target, opts)
        super owner, target, opts
       # add_location :body
       # add_location :header
        add_location :status
        add_location :header
        add_location :flags 
        
        add_match_type :match
        add_match_type :not_match     
        
        add_flag :none
        add_flag :request  
      end
    end

    class FilterTable < FXTable
      attr :filters
      def add_filter(filter)
        @filters << filter
        add_filter_row(filter)
      end
      
      def get_current_filter
        puts self.currentRow
      end
      
      def delete_row_by_index(index)
        return false if index < 0
        return false if index > self.numRows-1
        @filters.delete_at index
        self.clearItems
         init_columns
        
        @filters.each do |r|
          add_filter_row r
        end
        adjust_cell_width
        self.selectRow self.currentRow if self.currentRow >= 0
        true
      end
      
      def delete_current_row
        i = self.currentRow
        return false if i < 0
        delete_row_by_index i
      end

      def initialize( owner, filters=[], opts={} )
        @event_dispatcher_listeners = Hash.new
        parms = { :opts => TABLE_COL_SIZABLE|TABLE_ROW_SIZABLE|LAYOUT_FILL_X|LAYOUT_FILL_Y|TABLE_READONLY|LAYOUT_SIDE_TOP,
          :padding => 2
        }
        parms.update opts

        super(owner, parms)
        
        self.extend Watobo::Subscriber
        self.setBackColor(FXRGB(255, 255, 255))
        self.setCellColor(0, 0, FXRGB(255, 255, 255))
        self.setCellColor(0, 1, FXRGB(255, 240, 240))
        self.setCellColor(1, 0, FXRGB(240, 255, 240))
        self.setCellColor(1, 1, FXRGB(240, 240, 255))

        @columns=Hash.new
        
        @filters = []
        @filters.concat filters

        add_column "Location", 80
        add_column "Match", 80
        add_column "Pattern", 80
         add_column "Flags", 80


        init_columns
        
        @filters.each do |r|
          add_filter_row r
        end
        adjust_cell_width
        
        self.connect(SEL_SELECTED){|sender,sel,pos| 
                   self.selectRow pos.row
                 #  notify(:filter_selected, @filters[pos.row])
                   }
      end
      
      private
      
 def add_filter_row(filter)
   return false if filter.nil?
   row_index = self.getNumRows
        self.appendRows(1)

        self.rowHeader.setItemJustify(row_index, FXHeaderItem::RIGHT)
        self.setRowText(row_index, (row_index+1).to_s)

        index = @columns[:location][:order]
        self.setItemText(row_index, index, filter.name)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:match][:order]
        self.setItemText(row_index, index, filter.match_type.to_s)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:flags][:order]
        self.setItemText(row_index, index, filter.flags.join(","))
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:pattern][:order]
        self.setItemText(row_index, index, filter.pattern)
        self.getItem(row_index, index).justify = FXTableItem::LEFT


 end
      def add_column(name, width, order=0)
        o = ( order == 0 ) ? @columns.length : order
        @columns[name.downcase.to_sym] = { :name => name,
          :width => width,
          :order => o
        }

      end

      def adjust_cell_width()
        begin
          self.rowHeader.width = 30
          #self.fitColumnsToContents(0)
          @columns.each_with_index do |v,i|

            self.setColumnWidth(i, v[1][:width])
          end
        rescue => bang
          puts "!!!ERROR: adjustCellWidth"
          puts bang
          puts bang.backtrace
        end

      end

      def init_columns
        self.setTableSize(0, @columns.length)
        self.visibleRows = 5
        self.visibleColumns = @columns.length

        @columns.sort_by{|k,v| v[:order] }.each_with_index do |v,i|
          self.setColumnText( i, v[1][:name] )
        end

      end

    end

    class RequestFilterTable < FilterTable
      def initialize(owner, opts={})
        super owner, opts
        add_column "Action", 50
        add_column "Location", 80
        add_column "Pattern", 80
        add_column "Content", 80
        add_column "Filter", 80

        init_columns
        adjust_cell_width

      end
    end

    class RequestFilterDialog < FXDialogBox

      include Responder
      def filter
        f = Watobo::Interceptor::FilterChain.new
        f.set_filters @table.filters
        f
      end

     def initialize(owner, rule, settings = {} )
        super(owner, "Request Rule Filter", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 650, :height => 300)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
       
        @table = FilterTable.new(@main_frame, rule.filters)       
        @table_ctrl = RequestFilterCtrl.new(@main_frame, @table, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK)

        buttons_frame = FXHorizontalFrame.new(@main_frame, :opts => LAYOUT_FILL_X|LAYOUT_BOTTOM)
        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
        #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
      end

      private

      def onAccept(sender, sel, event)

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

    
    end
    
    class ResponseFilterDialog < FXDialogBox

      include Responder
      def filter
        f = Watobo::Interceptor::FilterChain.new
        f.set_filters @table.filters
        f
      end

      def initialize(owner, rule, settings = {} )
        super(owner, "Response Rule Filters", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 650, :height => 300)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
       
        @table = FilterTable.new(@main_frame, rule.filters)       
        @table_ctrl = ResponseFilterCtrl.new(@main_frame, @table, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK)

        buttons_frame = FXHorizontalFrame.new(@main_frame, :opts => LAYOUT_FILL_X|LAYOUT_BOTTOM)
        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
        #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end

        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
      end

      private

      def onAccept(sender, sel, event)
        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

    end
  end
end