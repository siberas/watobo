# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class SamplesFrame < FXVerticalFrame
          #
          # @param samples [Object] of type SampleSet
          def add(sample_set)
            @sample_sets << sample_set

            @table.sample_set = sample_set

            @sample_combo.clearItems
            @sample_sets.each do |s|
              item = @sample_combo.appendItem(s.name)
              @sample_combo.setItemData(item, s)
            end

            @sample_combo.setCurrentItem(@sample_sets.length - 1 )
          end

          def initialize(owner, opts)

            super(owner, opts)

            @sample_sets = []
            @samples_dt = FXDataTarget.new('')

            splitter = FXSplitter.new(self, LAYOUT_FILL_X | SPLITTER_HORIZONTAL | LAYOUT_FILL_Y | SPLITTER_TRACKING)
            vframe = FXVerticalFrame.new(splitter, :opts => FRAME_RAISED | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            frame = FXHorizontalFrame.new(vframe, :opts => LAYOUT_FILL_X)
            @sample_combo = FXComboBox.new(frame, 5, @samples_dt, FXDataTarget::ID_VALUE,
                                           COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)

            @sample_combo.connect(SEL_COMMAND, method(:select_sample))
            btn = FXButton.new(frame, "refresh")

            save_btn = FXButton.new(frame, "save")
            save_btn.disable

            @table = SampleTable.new(vframe, :opts => TABLE_COL_SIZABLE | TABLE_ROW_SIZABLE | LAYOUT_FILL_X | LAYOUT_FILL_Y | TABLE_READONLY | LAYOUT_SIDE_TOP)

            @table.subscribe(:chat_selected) do |chat|
              @request_viewer.setText(chat.request)
              @response_viewer.setText(chat.response)
            end

            btn.connect(SEL_COMMAND) {@table.refresh}

            vframe = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)


            @tabBook = FXTabBook.new(vframe, nil, 0, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_RIGHT)

            FXTabItem.new(@tabBook, "Request", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            @request_viewer = Watobo::Gui::RequestViewer.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            FXTabItem.new(@tabBook, "Response", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_RAISED)
            # frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
            @response_viewer = Watobo::Gui::ResponseViewer.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

          end

          private

          def select_sample(sender, sel, item)
            ci = sender.currentItem
            sample_set = sender.getItemData(ci)
            @table.sample_set = sample_set
          end
        end
      end
    end
  end
end

