# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class SimpleListGeneratorOptions < FXVerticalFrame

          def preferences
            list = []
            @valueList.each do |e|
              list << e.to_s
            end
            { :list => list }

          end

          def initialize(owner, prefs)
            super(owner, prefs)

            @list_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
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

            @loadButton = FXButton.new(frame, "Load", nil, nil, 0, :opts => FRAME_RAISED | FRAME_THICK)

            @loadButton.connect(SEL_COMMAND) {
              open_path = nil
              index = 0
              file = FXFileDialog.getOpenFilename(self, "Select File", open_path)
              File.readlines(file).each do |l|
                index = @valueList.appendItem(l.strip)
              end
              @valueList.makeItemVisible(index)
              @new_list_item_dt.value = ''
              @new_list_item.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            }


            list_border = FXVerticalFrame.new(@list_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_GROOVE, :padding => 0)
            @valueList = FXList.new(list_border, :opts => LIST_EXTENDEDSELECT | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @valueList.numVisible = 8

            @valueList.connect(SEL_COMMAND, method(:onValueSelect))


          end

          private

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

        end
      end
    end
  end
end
