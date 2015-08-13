# @private 
module Watobo#:nodoc: all
  module Plugin
    class Sqlmap
      class OptionsFrame < FXVerticalFrame
        def to_h

        end

        def set(settings)

        end
        
        def request=(req)
          @request_txt.text = req.join.gsub("\r",'')
        end
        
        def request
          @request_txt.to_s
        end
        
        def level
          @level_combo.getItemData(@level_combo.currentItem)
        end
        
        def risk
          @risk_combo.getItemData(@risk_combo.currentItem)
        end

        def technique
          return "BEUST" if @technique_combo.currentItem == 0
          @technique_combo.getItemData(@technique_combo.currentItem)
        end
        
        def manual_options
          "#{@manual_options_txt.text.strip}"
        end

        def initialize(owner, opts)
          super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
          
          self.extend Watobo::Subscriber
          
          groupbox = FXGroupBox.new(self, "Request", FRAME_GROOVE|LAYOUT_FILL_Y|LAYOUT_FILL_X, 0, 0, 0, 0)
          FXLabel.new(groupbox, "Enter a test request below or use 'SEND TO -> SQLMap' from the conversation-table menu (right-click).")
          frame = FXVerticalFrame.new(groupbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
          
          @request_txt = FXText.new(frame,  nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @request_txt.editable = true
          @request_txt.connect(SEL_CHANGED){ notify(:request_changed) }
          

          matrix = FXMatrix.new(self, 6, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)

          techniques = %w( All Time-based Error Boolean Union Stacked )
          FXLabel.new(matrix, "Technique:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @technique_combo = FXComboBox.new(matrix, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          techniques.each do |t|
            @technique_combo.appendItem(t, t[0])
            @technique_combo.numVisible = @technique_combo.numItems
          end

          #dbs = %w( MySQL Oracle PostgreSQL )
          #FXLabel.new(matrix, "DB:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          #@db_combo = FXComboBox.new(matrix, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          #dbs.each do |t|
          #  @db_combo.appendItem(t, t[0])
          #  @db_combo.numVisible = @db_combo.numItems
          #end

          risks = %w( 1 2 3 )
          FXLabel.new(matrix, "Risk:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @risk_combo = FXComboBox.new(matrix, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          risks.each do |r|
            @risk_combo.appendItem(r, r)
            @risk_combo.numVisible = @risk_combo.numItems
          end
          
           levels = (1..5)
          FXLabel.new(matrix, "Level:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @level_combo = FXComboBox.new(matrix, 20, nil, 0, FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
          levels.each do |l|
            @level_combo.appendItem(l.to_s, l.to_s)
            @level_combo.numVisible = @level_combo.numItems
          end
          
          frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_TOP)
          FXLabel.new(frame, "Manual Options:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @manual_options_txt = FXTextField.new(frame, 60, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
          
          
        end

        private

      end
    end
  end
end