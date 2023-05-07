# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer

      class FilterFrame < FXVerticalFrame

        def selection()
          filter = case @filter_dt.value
                   when 0
                     index = @patternCombo.currentItem
                     if @patternCombo.getItemText(index)
                       func = proc { |response|
                         pattern = @patternCombo.getItemText(index)
                         matchlist = []
                         response.each do |line|
                           if line =~ /#{pattern}/i then
                             match = $2
                             matchlist.push "#{match}"
                           end
                         end
                         matchlist
                       }
                       Filter.new(func, :filter_type => "SID", :value => "#{filter}", :info => "#{@patternCombo.getItemText(index)}")
                     else
                       nil
                     end

                   when 1

                     if @regex_filter_dt.value != '' then
                       func = proc { |response|
                         pattern = @regex_filter_dt.value
                         matchlist = []
                         # puts "...regex (#{pattern})..."
                         # puts response
                         #response.each do |line|
                         #if line =~ /#{pattern}/i then
                         if @negate_regex_cb.checked?
                           puts "* filter negate regex"
                           unless response.join =~ /#{pattern}/i then
                             match = $1
                             puts "* #{match}"
                             match = "#{response.join}" unless match
                             matchlist.push "#{match}"
                           end
                         else
                           if response.join =~ /#{pattern}/i then
                             match = $1
                             puts "* #{match}"
                             match = "#{response.join}" unless match
                             matchlist.push "#{match}"
                           end
                         end
                         #end
                         matchlist
                       }
                       Filter.new(func, :filter_type => "Regex", :value => "#{filter}", :info => "#{@regex_filter_dt.value}")
                     else
                       nil
                     end
                   end
          return filter
        end


        def initialize(owner, sidpatterns, opts)
          @sid_patterns = sidpatterns
          super(owner, opts)

          @filter_dt = FXDataTarget.new(0)
          group_box = FXGroupBox.new(self, "Filter", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
          sid_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          @sid_rb = FXRadioButton.new(sid_frame, "Session-ID", @filter_dt, FXDataTarget::ID_OPTION)

          regex_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          @regex_rb = FXRadioButton.new(regex_frame, "Regex", @filter_dt, FXDataTarget::ID_OPTION + 1)
          @regex_filter_dt = FXDataTarget.new('')
          @regex_filter = FXTextField.new(regex_frame, 1, :target => @regex_filter_dt, :selector => FXDataTarget::ID_VALUE,
                                          :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_COLUMN)
          @negate_regex_cb = FXCheckButton.new(group_box, "negate", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP | LAYOUT_RIGHT | LAYOUT_FILL_Y)
          # group_box = FXGroupBox.new(self, "Collection",LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
          # frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_GROOVE)
          # @collectionList = FXList.new(frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
          @filter_dt.connect(SEL_COMMAND) {
            @sid_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          }

          if @sid_patterns then
            @patternCombo = FXComboBox.new(sid_frame, @sid_patterns.length, nil, 0,
                                           :opts => COMBOBOX_INSERT_LAST | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
            @patternCombo.numVisible = @sid_patterns.length
            @sid_patterns.each do |pattern|
              @patternCombo.appendItem(pattern, nil)
            end
          else
            FXLabel.new(sid_frame, "NO SID PATTERNS DEFINED!")
            @sid_rb.disable
            @filter_dt.value = 1
            @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end

          @sid_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @regex_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          #  group_box = FXGroupBox.new(self, "Test", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
          #  @sample_count_dt = FXDataTarget.new('')
          #  frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          #  @sample_count = FXTextField.new(frame, 3, :target => @sample_count_dt, :selector => FXDataTarget::ID_VALUE,
          #                                  :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN)
          #  button = FXButton.new(frame, "Sample", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
          #  button.connect(SEL_COMMAND) do  |sender, sel, ptr|
          #    @interface.startSample()
          #  end
          #  frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          #  FXLabel.new(frame, "Matched:")


        end
      end
    end
  end
end