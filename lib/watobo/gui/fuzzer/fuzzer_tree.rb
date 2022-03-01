require_relative './create_action_dlg'
# @private
module Watobo #:nodoc: all
  module Gui
    module Fuzzer
      class FuzzerTree < FXTreeList
        attr :fuzzTags
        include Watobo::Gui::Icons

        def setup_listeners
          @event_dispatcher_listeners = {}

        end

        def subscribe(event, &callback)
          (@event_dispatcher_listeners[event] ||= []) << callback
        end

        def notify(event, *args)
          if @event_dispatcher_listeners[event]
            @event_dispatcher_listeners[event].each do |m|
              m.call(*args) if m.respond_to? :call
            end
          end
        end


        def addFilterItem(filter)
          return false if filter.nil?

          filter_root = self.findItem("Filters", nil, SEARCH_FORWARD | SEARCH_IGNORECASE)

          filter_item = self.appendItem(filter_root, "Filter: #{filter.filter_type}")
          self.setItemData(filter_item, filter)
          self.appendItem(filter_item, filter.info)
        end


        def addTag()
          dlg = CreateFuzzerDlg.new(self)
          if dlg.execute != 0 then
            tag = dlg.tag
            tag_is_valid = true
            @fuzzTags.each do |f|
              tag_is_valid = false if f.name == tag
            end
            if tag_is_valid and tag != ""
              new_fuzz_tag = FuzzerTag.new(tag)
              @fuzzTags.push new_fuzz_tag
              notify(:new_tag, new_fuzz_tag)
              refresh()
            else
              puts "!!! Could not create empty/used tag !!!"
            end
          end
        end

        def addTagItem(tag)

          tag_root = self.findItem("Tags", nil, SEARCH_FORWARD | SEARCH_IGNORECASE)

          item = self.findItem(tag.name, tag_root, SEARCH_FORWARD | SEARCH_IGNORECASE)

          return nil if item
          tag_item = self.appendItem(tag_root, "Tag: #{tag.name}")
          self.setItemData(tag_item, tag)

          #   item = self.appendItem(fuzz_item, "Generator", ICON_VULN, ICON_VULN)
          #  self.setItemData(item, :generator)

          tag.generators.each do |gen|
            addGeneratorItem(tag_item, gen)
          end


        end

        def initTree()
          fuzz_item = self.appendItem(nil, "Tags", ICON_FUZZ_TAG, ICON_FUZZ_TAG)
          self.setItemData(fuzz_item, :tags)

          item = self.appendItem(nil, "Filters", ICON_FUZZ_FILTER, ICON_FUZZ_FILTER)
          self.setItemData(item, :filter)

          #item = self.appendItem(nil, "Collector", ICON_INFO, ICON_INFO)
          #self.setItemData(item, :collector)
        end

        def addAction(generator)
          dlg = CreateActionDlg.new(self)
          if dlg.execute != 0 then
            puts "new action"
            new_action = dlg.getAction()
            generator.addAction(new_action) if new_action
            refresh()
          end
        end

        def addGeneratorItem(tag_item, generator)
          begin
            item = self.appendItem(tag_item, generator.genType, ICON_FUZZ_GENERATOR, ICON_FUZZ_GENERATOR)
            self.setItemData(item, generator)
            self.appendItem(item, generator.info)

            generator.actions.each do |a|
              action_item = self.appendItem(item, a.action_type, ICON_FUZZER, ICON_FUZZER)
              self.setItemData(action_item, a)
              self.appendItem(action_item, a.info)
            end
            self.expandTree(item)
          rescue => bang
            puts "!ERROR: could not add GeneratorItem"
            puts bang
          end
        end

        def expandSubtree(item = nil)
          if item
            self.expandTree(item)
            item.each do |child|
              expandSubtree(child)
            end
          end
        end

        def expandSettings(item = nil)
          self.each do |root_item|
            expandSubtree(root_item)
          end
        end

        def refresh()
          self.clearItems()
          initTree()
          @fuzzTags.each do |f|
            addTagItem(f)
          end

          @filters.each do |f|
            addFilterItem(f)
          end

          expandSettings()
        end

        def initialize(owner, project)
          super(owner, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | LAYOUT_TOP | LAYOUT_RIGHT | TREELIST_SHOWS_LINES | TREELIST_SHOWS_BOXES | TREELIST_ROOT_BOXES | TREELIST_EXTENDEDSELECT)
          #  f = Fuzzer.new("FUZZ")
          @fuzzTags = []
          @project = project
          @filters = []

          setup_listeners()

          refresh()


          self.connect(SEL_COMMAND) do |sender, sel, item|
            if self.itemLeaf?(item)
              getApp().beginWaitCursor do
                begin
                  if item.data
                    if item.data.is_a? Finding
                      @interface.show_vuln(item.data)
                    end
                  end
                rescue => bang
                  puts "!!! Error: could not show selected finding"
                  puts bang
                end
              end
            elsif item.data == :title then
              @interface.show_vuln(item.first.data) if item.first.data
            end
          end

          self.connect(SEL_DOUBLECLICKED) do |sender, sel, item|
            if self.itemLeaf?(item)
              begin
                if item.data and item.data.is_a? Symbol then
                  case item.data
                  when :tags
                    addTag()
                  when :filter
                    dlg = CreateFilterDlg.new(self, @project)
                    if dlg.execute != 0 then
                      f = dlg.filter
                      notify(:new_filter, f)
                      @filters.push f
                      refresh()
                    end
                  end
                elsif item.data.respond_to? :is_tag?
                  dlg = CreateGeneratorDlg.new(self)
                  if dlg.execute != 0 then
                    # puts "new generator"
                    fuzzer = item.data
                    gen = dlg.getGenerator(fuzzer)
                    fuzzer.addGenerator(gen)
                    refresh()
                  end
                elsif item.data.respond_to? :is_generator?
                  gen = item.data
                  addAction(gen)

                else
                  puts "Unknown Object: #{item.data.class}"
                end

              rescue => bang
                puts "!!! Error: could not show selected finding"
                puts bang
              end
            end
          end

          self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
            unless event.moved?
              item = sender.getItemAt(event.win_x, event.win_y)

              FXMenuPane.new(self) do |menu_pane|
                data = item ? self.getItemData(item) : nil
                if data.is_a? Symbol
                  case data
                  when :tags

                    m = FXMenuCommand.new(menu_pane, "Add Tag..")
                    m.connect(SEL_COMMAND) {
                      addTag()
                    }

                  when :filter

                    m = FXMenuCommand.new(menu_pane, "Add Filter..")
                    m.connect(SEL_COMMAND) {
                      dlg = CreateFilterDlg.new(self, @project)
                      if dlg.execute != 0 then
                        f = dlg.filter
                        notify(:new_filter, f)
                        @filters.push f
                        refresh()
                      end
                    }
                  end
                elsif data.respond_to? :is_tag?
                  m = FXMenuCommand.new(menu_pane, "Add Generator..")
                  m.connect(SEL_COMMAND) {
                    dlg = CreateGeneratorDlg.new(self)
                    if dlg.execute != 0 then
                      # puts "new generator"
                      fuzzer = data
                      gen = dlg.getGenerator(fuzzer)
                      fuzzer.addGenerator(gen)
                      refresh()
                    end
                  }
                  m = FXMenuCommand.new(menu_pane, "Remove Tag")
                  m.connect(SEL_COMMAND) {
                    # puts "Removing Tag [#{data.name}]"
                    if @fuzzTags.include?(data)
                      # puts "...found tag"
                      @fuzzTags.delete(data)
                    end
                    notify(:remove_tag, data)
                    refresh()
                  }
                elsif data.respond_to? :is_generator?
                  m = FXMenuCommand.new(menu_pane, "Add Action..")
                  m.connect(SEL_COMMAND) {
                    gen = self.getItemData(item)
                    addAction(gen)
                  }
                  m = FXMenuCommand.new(menu_pane, "Remove Generator")
                  m.connect(SEL_COMMAND) {
                    tag = self.getItemData(item.parent)
                    tag.deleteGenerator(data)
                    refresh()
                  }
                elsif data.respond_to? :is_action?
                  m = FXMenuCommand.new(menu_pane, "Remove Action")
                  m.connect(SEL_COMMAND) {
                    gen = self.getItemData(item.parent)
                    gen.removeAction(data)
                    refresh()
                  }
                elsif data.respond_to? :is_filter?
                  m = FXMenuCommand.new(menu_pane, "Remove Filter")
                  m.connect(SEL_COMMAND) {
                    @filters.delete(data)
                    notify(:remove_filter, data)
                    refresh()
                  }
                else
                  puts "Unknown Object: #{data.class}"
                end

                menu_pane.create
                menu_pane.popup(nil, event.root_x, event.root_y)


                app.runModalWhileShown(menu_pane)
              end
            end
          end

        end
      end
    end
  end
end