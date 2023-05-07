if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  $: << inc_path

  require 'watobo'
  require 'watobo/gui'

  require 'fox16'

  include Fox
  include Watobo::Constants

end

# @private 
module Watobo #:nodoc: all
  module Gui

    class CheckBoxTreeItem < FXTreeItem
      attr_accessor :checked

      include Watobo::Gui::Icons

      def check
        begin
          @checked = true
          self.setOpenIcon(ICON_CB_CHECKED)
          self.setClosedIcon(ICON_CB_CHECKED)
            # opened = true
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
      end

      alias :checked? :checked

      def uncheck
        begin
          @checked = false
          self.setOpenIcon(ICON_CB_UNCHECKED)
          self.setClosedIcon(ICON_CB_UNCHECKED)
            #opened = false
        rescue => bang
          puts "!!!ERROR: could not uncheck item"
        end
      end

      # check if item is leaf
      # if item.data is not a symbol, we expect it a leaf
      def isLeaf?
        !data.is_a? Symbol
      end

      def toggle
        if @checked
          uncheck
        else
          check
        end
      end

      def initialize(item_text, item_status = false)
        super item_text
        @checked = item_status
        #icon = ICON_CB_CHECKED
        #icon = ICON_CB_UNCHECKED if not status
        #super(text, icon, icon, data)
        #   data = item_data
        if @checked
          check
        else
          uncheck
        end
      end
    end

    class CheckBoxTreeList < FXTreeList
      include Watobo::Gui::Icons
      include Watobo::Subscriber
      #------------------------------
      # C R E A T E T R E E
      #------------------------------
      # elements[] = [{
      #                   :name => element_name, number of subtrees controlled via pipe-char, e.g. <level1>|<level2>|item
      #                   :enabled => true|false,
      #                   :data => object|string|...
      #                   }, {..} ]
      # last part of name will be the leaf node containing the data object
      def elements=(elements)
        self.clearItems()
        #return false if elements.length > 0
        elements.each do |e|

          # puts icon.class.to_s
          node = nil
          levels = e[:name].split('|')
          begin
            #puts "Processing: #{e[:name]} > #{e[:data].class}" if $DEBUG
            levels.each_with_index do |l, i|
              #puts "#{l} - #{l.class}"
              item = self.findItem(l, node, SEARCH_FORWARD | SEARCH_IGNORECASE)

              if item.nil? then
                # new_item = FXTreeItem.new(l, ICON_CB_CHECKED, ICON_CB_CHECKED)
                # new_item.extend CheckboxMixin
                new_item = CheckBoxTreeItem.new(l, e[:enabled])
                # item = self.appendItem(node, l, ICON_CB_CHECKED, ICON_CB_CHECKED)
                item = self.appendItem(node, new_item)

              end
              node = item
            end

            # set data to leaf object
            self.setItemData(node, e[:data])
            updateParent(node)
          rescue => bang
            puts bang
            puts bang.backtrace
          end
        end
      end


      def updateParent(child)
        return false unless child.parent
        parent = child
        while parent.parent
          parent = parent.parent

          ec = 0
          parent.each do |item|
            #data = self.getItemData(item)
            #ec += 1 if data[:enabled]
            if item.isLeaf?
              ec += 1 if item.checked?
            else
              ec += 1 if item.data == :all
            end
          end

          if ec == 0 then
            # puts "no childs selected"
            icon = ICON_CB_UNCHECKED
            self.setItemData(parent, :none)
          elsif ec < parent.numChildren then
            # puts "not all childs are selected"
            icon = ICON_CB_CHECKED_ORANGE
            self.setItemData(parent, :partly)
          else
            # puts "all childs have been selected"
            icon = ICON_CB_CHECKED
            self.setItemData(parent, :all)
          end

          self.setItemOpenIcon(parent, icon)
          self.setItemClosedIcon(parent, icon)
        end
      end

      # recursive function to enumerate all checked data items
      # @return [Array] of data items
      def getCheckedData(root = self)
        selected = []
        root.each do |c|
          if c.isLeaf?
            selected << c.data if c.checked?
          else
            selected.concat getCheckedData(c)
          end
        end
        selected
      end

      def checkAll
        self.each do |r|
          checkAllChildren(r)
        end
        self.update
      end

      def uncheckAll
        self.each do |n|
          uncheckAllChildren n
        end
      end


      def uncheckAllChildren(node)
        node.uncheck
        node.data = :none unless node.isLeaf?
        node.each do |child|
          #uncheckItem(child)
          uncheckAllChildren(child)
        end
        update
      end

      def checkAllChildren(node)
        node.check
        node.data = :all unless node.isLeaf?
        node.each do |child|
          #uncheckItem(child)
          checkAllChildren(child)
        end
        update
      end

      def initialize(parent)

        @parent = parent
        super(parent, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y |
            TREELIST_SHOWS_LINES |
            TREELIST_SHOWS_BOXES |
            TREELIST_ROOT_BOXES |
            #TREELIST_EXTENDEDSELECT|
            TREELIST_MULTIPLESELECT

        )
        #LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT

        self.connect(SEL_COMMAND) do |sender, sel, item|
          if $DEBUG
            puts "\n---\n>>> SEL_SELECTED"
            puts "Selected Item: #{item}"
            puts "ItemLeaf?: #{self.itemLeaf?(item).class}"
            puts "ItemSelected?: #{item.selected?}"
            puts "ItemData: #{item.data.class}"
            if item.parent
              puts "Member Of: #{item.parent}"
              puts "Has Brothers: #{item.parent.numChildren}"
            end
          end

          if self.itemLeaf?(item) then
            #toggleState(item)
            item.toggle
            notify(:item_selected, item.data)
          else
            data = self.getItemData(item)

            new_state = case data
                        when :partly
                          #  puts data
                          icon = ICON_CB_UNCHECKED
                          uncheckAllChildren(item)
                          :none
                        when :none
                          #  puts data
                          icon = ICON_CB_CHECKED
                          checkAllChildren(item)
                          :all
                        when :all
                          # puts data
                          icon = ICON_CB_UNCHECKED
                          uncheckAllChildren(item)
                          :none
                        else
                          icon = ICON_CB_CHECKED
                          checkAllChildren(item)
                          :all
                        end

            self.setItemData(item, new_state)
            self.setItemClosedIcon(item, icon)
            self.setItemOpenIcon(item, icon)
          end
          updateParent(item)

          # kill selected item because we don't want it to be highlighted
          self.killSelection(false)
          notify(:sel_changed)
        end

      end
    end
    #--
  end
end

##########################

if $0 == __FILE__
  # @private 
  module Watobo #:nodoc: all
    module Gui

      @application ||= FXApp.new('LayoutTester', 'FoxTest')
      class TestGui < FXMainWindow

        class TreeDlg < FXDialogBox

          #   include Responder
          def initialize(parent, project = nil, prefs = {})
            super(parent, "CheckBox Dialog", DECOR_ALL, :width => 300, :height => 400)
            # FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
            frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE)
            elements = []
            num_root_nodes = 4
            max_child_nodes = 4
            num_root_nodes.times do |ri|
              max_child_nodes.times do |si|
                name = "root#{ri}|sub#{si}"
                data = name + "-data"
                e = {:name => name, :enabled => false, :data => data}
                elements << e
              end
            end
            @cbtree = CheckBoxTreeList.new(frame)
            @cbtree.elements = elements

          end

        end

        def leave
          d = @cbtree.getCheckedData
          #puts d.class
          #puts d
          exit
        end

        def initialize(app)
          # Call base class initializer first
          super(app, "Test Application", :width => 800, :height => 600)
          frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_GROOVE)

          elements = []
          num_root_nodes = 4
          max_child_nodes = 4
          num_root_nodes.times do |ri|
            max_child_nodes.times do |si|
              name = "root#{ri}|sub#{si}"
              data = name + "-data"
              e = {:name => name, :enabled => false, :data => data}
              elements << e
            end
          end

          @cbtree = CheckBoxTreeList.new(frame)
          @cbtree.elements = elements

          FXButton.new(frame, "Select All", :opts => FRAME_THICK | FRAME_RAISED | LAYOUT_FILL_X | LAYOUT_TOP | LAYOUT_LEFT).connect(SEL_COMMAND) { @cbtree.checkAll }
          FXButton.new(frame, "Deselect All", :opts => FRAME_THICK | FRAME_RAISED | LAYOUT_FILL_X | LAYOUT_TOP | LAYOUT_LEFT).connect(SEL_COMMAND) { @cbtree.uncheckAll }

          FXButton.new(frame, "Open TreeDialog", :opts => FRAME_THICK | FRAME_RAISED | LAYOUT_FILL_X | LAYOUT_TOP | LAYOUT_LEFT).connect(SEL_COMMAND) {
            dlg = TreeDlg.new(self)
            if dlg.execute != 0 then
              puts "* Dialog Finished"
            else
              puts "Dialog Canceled"
            end
          }

          FXButton.new(frame, "Exit", :opts => FRAME_THICK | FRAME_RAISED | LAYOUT_FILL_X | LAYOUT_TOP | LAYOUT_LEFT).connect(SEL_COMMAND) { leave }
        end

        def create
          super # Create the windows
          show(PLACEMENT_SCREEN) # Make the main window appear
        end
      end
      #  application = FXApp.new('LayoutTester', 'FoxTest')
      TestGui.new(@application)
      @application.create
      @application.run

    end
  end
end