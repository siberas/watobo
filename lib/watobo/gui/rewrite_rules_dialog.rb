# @private 
module Watobo#:nodoc: all
  module Gui
    class RulesTableCtrl < FXHorizontalFrame
      attr_accessor :target
      
      def initialize(owner,target = nil, opts)
        @target = target
        super owner, opts
        matrix = FXMatrix.new(self, 4, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        %w( Action Location Pattern Content).each do |l|
          FXLabel.new(matrix, l)
        end
        
        @actions_combo = FXComboBox.new(matrix, 10, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK)
        #@filterCombo.width =200

        @actions_combo.numVisible = 0
        @actions_combo.numColumns = 10
        @actions_combo.editable = false
        @actions_combo.connect(SEL_COMMAND){}
        
        @locations_combo = FXComboBox.new(matrix, 10, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK)
        #@filterCombo.width =200

        @locations_combo.numVisible = 0
        @locations_combo.numColumns = 10
        @locations_combo.editable = false
        @locations_combo.connect(SEL_COMMAND){}
        
        @pattern_txt = FXTextField.new(matrix, 20, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
         @content_txt = FXTextField.new(matrix, 20, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
         
         frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
         top_btn_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
      
        @del_btn = FXButton.new(top_btn_frame, "Del" ,  nil, nil)
        @del_btn.enable
        @del_btn.connect(SEL_COMMAND){ delete_rule }

     #   @edit_btn = FXButton.new(top_btn_frame, "Edit ..." ,  nil, nil)
     #   @edit_btn.enable
     #   @edit_btn.connect(SEL_COMMAND){ delete_rule }

        @up_btn = FXButton.new(top_btn_frame, "Up" ,  nil, nil)
        @up_btn.enable

        @down_btn = FXButton.new(top_btn_frame, "Down" ,  nil, nil)
        @down_btn.enable
        
         @filter_btn = FXButton.new(top_btn_frame, "Filter" ,  nil, nil)
        @filter_btn.enable
        @filter_btn.connect(SEL_COMMAND){ open_filter_dialog }
        
        
        add_btn_frame = FXHorizontalFrame.new(frame,:opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @add_btn = FXButton.new(add_btn_frame, "Add ..." ,  nil, nil, )
        @add_btn.enable
        @add_btn.connect(SEL_COMMAND){ add_rule }

      end

      private

      def init_handlers()

      end

      def clear_actions
        @actions_combo.clearItems()
      end

      def add_action(a)
        @actions_combo.appendItem(a.to_s, a)
        @actions_combo.numVisible = @actions_combo.numItems
      end

      def add_location(l)
        @locations_combo.appendItem(l.to_s, l)
         @locations_combo.numVisible = @locations_combo.numItems
      end
      
      def delete_rule
       @target.delete_current_row if @target.respond_to? :delete_current_row
        
      end
      
      def add_rule
        return false if @target.nil?
        #TODO: Add some checks if rule is ok
         @target.add_rule Watobo::Interceptor::CarverRule.new(:action => @actions_combo.getItemData(@actions_combo.currentItem), 
                                                              :location => @locations_combo.getItemData(@locations_combo.currentItem),
                                                              :pattern => @pattern_txt.text, 
                                                              :content => @content_txt.text, 
                                                              :filter => nil
                                                              )
      end
      
      def open_filter_dialog
      
      end

    end
    
    class RequestRulesCtrl < RulesTableCtrl
      def initialize(owner, target, opts)
        super owner, target, opts
        add_action :rewrite
        add_action :flag
        add_location :url
        add_location :body
        add_location :header
        add_location :cookie
        add_location :http_parm
        
      end
      
      def open_filter_dialog
         rule = @target.current_rule
        return false if rule.nil?
        dlg = Watobo::Gui::RequestFilterDialog.new( self, rule )
        if dlg.execute != 0 then
        # TODO: Apply interceptor settings
        rule.set_filter dlg.filter
        @target.reset_table
        
        end
      end
    end
    
    class ResponseRulesCtrl < RulesTableCtrl
      def initialize(owner, target, opts)
        super owner, target, opts
        add_action :rewrite
        add_location :body
        add_location :header
        add_location :replace_all        
      end
      
      def open_filter_dialog
         rule = @target.current_rule
        return false if rule.nil?
        dlg = Watobo::Gui::ResponseFilterDialog.new( self, rule )
        if dlg.execute != 0 then
        # TODO: Apply interceptor settings
        rule.set_filter dlg.filter
        @target.reset_table
        end
      end
    end

    class RulesTable < FXTable
      attr :rules
      def add_rule(rule)
        @rules << rule
        add_rule_row(rule)
      end
      
      def current_rule
        return nil if self.currentRow < 0
        return @rules[self.currentRow]
      end
      
      def delete_row_by_index(index)
        return false if index < 0
        return false if index > self.numRows-1
        @rules.delete_at index
        self.clearItems
        reset_table
        true
      end
      
      def reset_table
        init_columns
        
        @rules.each do |r|
          add_rule_row r
        end
        adjust_cell_width
        self.selectRow self.currentRow if self.currentRow >= 0
      end
      
      def delete_current_row
        i = self.currentRow
        return false if i < 0
        delete_row_by_index i
      end

      def initialize( owner, rules=[], opts={} )
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
        
        @rules = []
        @rules.concat rules
        
         add_column "Action", 50
        add_column "Location", 80
        add_column "Pattern", 80
        add_column "Content", 80
        add_column "Filter", 80

        init_columns
        
        @rules.each do |r|
          add_rule_row r
        end
        adjust_cell_width
        
        self.connect(SEL_SELECTED){|sender,sel,pos| 
                   self.selectRow pos.row
                 #  notify(:rule_selected, @rules[pos.row])
                   }
      end
      
      private
      
 def add_rule_row(rule)
   row_index = self.getNumRows
        self.appendRows(1)

        self.rowHeader.setItemJustify(row_index, FXHeaderItem::RIGHT)
        self.setRowText(row_index, (row_index+1).to_s)

        index = @columns[:action][:order]
        self.setItemText(row_index, index, rule.action_name)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:location][:order]
        self.setItemText(row_index, index, rule.location_name)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:pattern][:order]
        self.setItemText(row_index, index, rule.pattern_name)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:content][:order]
        self.setItemText(row_index, index, rule.content_name)
        self.getItem(row_index, index).justify = FXTableItem::LEFT

        index = @columns[:filter][:order]
        self.setItemText(row_index, index, rule.filter_name)
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

    class RequestRulesTable < RulesTable
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

    class RewriteRulesDialog < FXDialogBox

      include Responder
      def request_rules
        @request_rules_table.rules
      end

      def response_rules
        @response_rules_table.rules
      end

      def initialize(owner, settings = {} )
        super(owner, "Rewrite Rules", DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 650, :height => 610)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        init_request_rules(@main_frame)
        init_response_rules(@main_frame)

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

      def init_request_rules(owner)

        gbframe = FXGroupBox.new(owner, "Request Rules", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        
        @request_rules_table = RulesTable.new(frame, Interceptor::RequestCarver.rules)       
        @request_rules_ctrl = RequestRulesCtrl.new(gbframe, @request_rules_table, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK)
      end

      def init_response_rules(owner)
        gbframe = FXGroupBox.new(owner, "Response Rules", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        
        @response_rules_table = RulesTable.new(frame, Interceptor::ResponseCarver.rules)       
        @response_rules_ctrl = ResponseRulesCtrl.new(gbframe, @response_rules_table, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK)
      end
    end
  end
end