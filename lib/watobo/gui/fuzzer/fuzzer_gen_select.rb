# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer
      class FuzzerGenSelect < FXVerticalFrame

        include Watobo

        def updateFields
          @file_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @gen_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @list_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @sourceFileText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @cstartText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @cstopText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @cstepText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        end

        def selectFile(sender, sel, ptr)
          filename = FXFileDialog.getOpenFilename(self, "Select Source File", @source_file.value)
          if filename != "" then
            if File.exist?(filename) then
              @source_file.value = filename
              @sourceFileText.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end

          end
        end

        def onValueSelect(sender, sel, selected)
          item = @valueList.currentItem
          if item >= 0 then
            @new_list_item_dt.value = @valueList.getItemText(item)
          end
        end

        def removeValue(sender, sel, ptr)
          item = @valueList.currentItem
          if item >= 0 then
            @valueList.removeItem(item)
          end
        end

        def addValue(sender, sel, ptr)
          if @new_list_item_dt.value != '' then
            index = @valueList.appendItem(@new_list_item_dt.value)
            @valueList.makeItemVisible(index)
            @new_list_item_dt.value = ''
            @new_list_item.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end
        end

        def createGenerator(fuzzer)
          gen = case @source_dt.value
                when 0
                  #puts "File Generator Selected"
                  Watobo::FuzzFile.new(fuzzer,
                                       @source_file.value)
                when 1
                  # counter selected
                  Watobo::FuzzCounter.new(fuzzer,
                                          :start => @cstart.value.to_i,
                                          :stop => @cstop.value.to_i,
                                          #:count => @ccount.value.to_i,
                                          :step => @cstep.value.to_i)
                when 2

                  list = []
                  @valueList.each do |item|
                    # puts item
                    list.push item.text
                  end
                  Watobo::FuzzList.new(fuzzer, list)
                end

          return gen
        end

        def disableFrame(frame)
          frame.children.each do |c|
            c.children.each do |sc|
              sc.disable
              sc.selBackColor = sc.parent.backColor if sc.respond_to? :selBackColor
            end
            c.disable
            c.selBackColor = c.parent.backColor if c.respond_to? :selBackColor
          end
        end

        def enableFrame(frame)
          frame.children.each do |c|
            c.children.each do |sc|
              sc.enable
              sc.selBackColor = FXColor::White if sc.respond_to? :selBackColor
            end
            c.enable
            c.selBackColor = FXColor::White if c.respond_to? :selBackColor
          end
        end

        def initialize(owner, interface, opts)
          super(owner, opts)

          @interface = interface

          group_box = FXGroupBox.new(self, "Select Source", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X | LAYOUT_FILL_Y, 0, 0, 0, 0)
          @source_dt = FXDataTarget.new(0)

          @source_dt.connect(SEL_COMMAND) do
            case @source_dt.value
            when 0
              # puts "File"
              enableFrame(@file_select_frame)
              disableFrame(@counter_frame)
              disableFrame(@list_frame)
            when 1
              disableFrame(@file_select_frame)
              disableFrame(@list_frame)
              enableFrame(@counter_frame)
              # puts "Generator"
            when 2
              disableFrame(@counter_frame)
              enableFrame(@list_frame)
              disableFrame(@file_select_frame)
              # puts "List"
            end
            @file_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @gen_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @list_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          end
          file_rb_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
          @file_rb = FXRadioButton.new(file_rb_frame, "File", @source_dt, FXDataTarget::ID_OPTION)

          @file_select_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X, :padding => 0)
          @source_file = FXDataTarget.new('')
          @sourceFileText = FXTextField.new(@file_select_frame, 1, :target => @source_file, :selector => FXDataTarget::ID_VALUE,
                                            :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_COLUMN)
          button = FXButton.new(@file_select_frame, "Select")
          button.connect(SEL_COMMAND, method(:selectFile))

          counter_rb_frame = FXHorizontalFrame.new(group_box, LAYOUT_FILL_X)
          @gen_rb = FXRadioButton.new(counter_rb_frame, "Counter", @source_dt, FXDataTarget::ID_OPTION + 1)
          @counter_frame = FXHorizontalFrame.new(group_box, LAYOUT_FILL_X, :padding => 0)

          @cstep = FXDataTarget.new(0)
          @cstepText = FXTextField.new(@counter_frame, 3, :target => @cstep, :selector => FXDataTarget::ID_VALUE,
                                       :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_RIGHT)
          FXLabel.new(@counter_frame, "Step", nil, :opts => LAYOUT_RIGHT)


          @cstop = FXDataTarget.new(0)
          @cstopText = FXTextField.new(@counter_frame, 3, :target => @cstop, :selector => FXDataTarget::ID_VALUE,
                                       :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_RIGHT)
          FXLabel.new(@counter_frame, "Stop", nil, :opts => LAYOUT_RIGHT)


          @cstart = FXDataTarget.new(0)
          @cstartText = FXTextField.new(@counter_frame, 3, :target => @cstart, :selector => FXDataTarget::ID_VALUE,
                                        :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_RIGHT)
          FXLabel.new(@counter_frame, "Start", nil, :opts => LAYOUT_RIGHT)

          list_rb_frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @list_rb = FXRadioButton.new(list_rb_frame, "List", @source_dt, FXDataTarget::ID_OPTION + 2)
          @list_frame = FXVerticalFrame.new(list_rb_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
          frame = FXHorizontalFrame.new(@list_frame, :opts => LAYOUT_FILL_X, :padding => 0)

          @new_list_item_dt = FXDataTarget.new('')
          @new_list_item = FXTextField.new(frame, 10,
                                           :target => @new_list_item_dt, :selector => FXDataTarget::ID_VALUE,
                                           :opts => TEXTFIELD_NORMAL | LAYOUT_SIDE_LEFT | LAYOUT_FILL_X)
          #   FXLabel.new(frame, "Value: ")
          @addButton = FXButton.new(frame, "Add", nil, nil, 0, :opts => FRAME_RAISED | FRAME_THICK)
          @addButton.connect(SEL_COMMAND, method(:addValue))
          @remButton = FXButton.new(frame, "Remove", nil, nil, 0, :opts => FRAME_RAISED | FRAME_THICK)
          @remButton.connect(SEL_COMMAND, method(:removeValue))

          list_border = FXVerticalFrame.new(@list_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_GROOVE, :padding => 0)
          @valueList = FXList.new(list_border, :opts => LIST_EXTENDEDSELECT | LAYOUT_FILL_X | LAYOUT_FILL_Y)
          @valueList.numVisible = 4

          @valueList.connect(SEL_COMMAND, method(:onValueSelect))

          enableFrame(@file_select_frame)
          disableFrame(@counter_frame)
          disableFrame(@list_frame)

          updateFields()

        end
      end
    end
  end
end
