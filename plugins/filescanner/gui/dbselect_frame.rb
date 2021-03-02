# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Filescanner
      class Gui
        class DBSelectFrame < FXVerticalFrame


          def select_db(db_name)
            @db_listbox.numItems.times do |i|
              if db_name == @db_listbox.getItemData(i)
                @db_listbox.currentItem = i
              end
            end
          end

          def get_db_name
            i = @db_listbox.currentItem
            db = ''
            db = @db_listbox.getItemData(i) if i >= 0
            db
          end

          def get_db_list
            l = []
            @db_listbox.numItems.times do |i|
              l << @db_listbox.getItemData(i)
            end
            l
          end

          def db_list=(dbl)

          end

          def initialize(parent, db_list, opts)
            super(parent, opts)
            @db_list = []
            db_list.each do |f|
              @db_list << f if File.exist? f
            end

            FXLabel.new(self, "Each filename must be in a seperate line, e.g. DirBuster-DBs")
            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)

            @db_listbox = FXListBox.new(frame, :opts => LAYOUT_FILL_X | FRAME_SUNKEN | FRAME_THICK)
            @db_list.each do |db|
              item = @db_listbox.appendItem(db)
              @db_listbox.setItemData(@db_listbox.numItems - 1, db)
            end
            @db_listbox.numVisible = @db_listbox.numItems

            @add_db_btn = FXButton.new(frame, "add")
            @add_db_btn.connect(SEL_COMMAND) { add_db }
          end

          private

          def add_db
            db_path = File.dirname(get_db_name)
            db = FXFileDialog.getOpenFilename(self, "Open DB", db_path, "All Files (*)")
            unless db.empty?
              item = @db_listbox.appendItem(db)
              i = @db_listbox.numItems - 1
              @db_listbox.setItemData(i, db)
              @db_listbox.currentItem = i
            end
          end
        end
      end
    end
  end
end
