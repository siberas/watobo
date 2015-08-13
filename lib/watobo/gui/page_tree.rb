 #require 'qcustomize.rb'

# @private 
module Watobo#:nodoc: all
  module Gui
    class PageTree < FXTreeList

      attr :page

      include Watobo::Constants
      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def reload()
        self.clearItems

      # @interface.updateRequestTable(@project)
      end

      def page=(p)
        @page = p
        refresh_tree
      end

      def refresh_tree()
        self.clearItems
        unless @page.nil?
          if page.forms.length > 0
          page.forms.each do |f|
            add_form_item f
          end
          else
            self.appendItem(nil, "Forms ()", nil, nil)
          end
        end
      # @interface.updateRequestTable(@project)
      end

      def expandFullTree(item)
        self.expandTree(item)
        item.each do |c|
          expandFullTree(c) if !self.itemLeaf?(c)
        end
      end

      def collapseFullTree(item)
        self.collapseTree(item)
        item.each do |c|
          collapseFullTree(c) if !self.itemLeaf?(c)
        end
      end

      def hidden?(chat)

        #TODO: Filter
        false
      end

      def initialize(parent, page=nil, prefs={})
        @page = page
        @quick_filter = Hash.new
        opts = LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT
        opts = prefs[:opts] if prefs.has_key? :opts
        super(parent, :opts => opts)
        @event_dispatcher_listeners = Hash.new
        @filters = {
          :element => []
        }

        forms = self.appendItem(nil, "load a new page first!", nil, nil)

        self.connect(SEL_COMMAND) do |sender, sel, item|
          
          if item.data.is_a? Mechanize::Form
               puts "Form Selected"
               notify(:form_selected, item.data)
          elsif item.data.is_a? Mechanize::Form::Field
            puts "Field Selected"
            notify(:form_selected, item.parent.data)
            notify(:field_selected, item)
          end

        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          exclude_site = nil
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|

            #
              item = sender.getItemAt(event.win_x, event.win_y)

              unless item.nil?

                unless self.itemLeaf?(item)
                  FXMenuSeparator.new(menu_pane)
                  FXMenuCommand.new(menu_pane, "expand tree" ).connect(SEL_COMMAND) {
                    expandFullTree(item)
                  }

                  FXMenuCommand.new(menu_pane, "collapse tree" ).connect(SEL_COMMAND) {
                    self.collapseFullTree(item)
                  }

                end

                data = self.getItemData(item)
                
                if item == "Forms" then
                  puts "Right Click Forms"
                  FXMenuSeparator.new(menu_pane)

                  FXMenuCommand.new(menu_pane, "found Form Item" ).connect(SEL_COMMAND) {

                    notify(:add_site_to_scope, item.to_s)
                  }
                else
                  puts "Didn't click Forms"

                end
              # submenu = FXMenuPane.new(self) do |domain_menu|

              #   @filtered_domains.each do |domain, filter|
              #     hide_domain = FXMenuCommand.new(domain_menu, "#{domain}" )
              #     hide_domain.connect(SEL_COMMAND) {
              #       @interface.default_settings[:domain_filters].delete(filter)
              #       @filtered_domains.clear
              #       @interface.updateTreeLists
              #     }
              #   end
              # end
              # FXMenuCascade.new(menu_pane, "Unhide Domains", nil, submenu)

              end
              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)

            end
          end
        end
      end

      private

      def get_node_class(name)
        return nil if name.nil?
        return nil if name.empty?
        puts "get_node_class #{name}"

        ccname = Watobo::Utils.camelcase(name)
        nc = nil
        unless Watobo::Gui::PageTree.const_defined? ccname
          puts "Creating new class #{ccname}"
          Watobo::Gui::PageTree.class_eval("class #{ccname};end")
          nc = Watobo::Gui::PageTree.const_get(ccname)
        else
          puts "Get existing class #{ccname}"
          nc = Watobo::Gui::PageTree.const_get(ccname)
        end
        puts nc.name
        nc
      end

      def add_form_item(form)

        node_name = "Forms"
        #nc = get_node_class node_name
        # form_item = self.findItem(node_name, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)
        form_item = self.findItemByData(node_name.to_sym, nil, SEARCH_FORWARD)

       
        if form_item.nil?
          # found new site
          form_item = self.appendItem(nil, node_name, nil, nil)
        #site = @findings_tree.moveItem(project.first,project,site)
        self.setItemData(form_item, node_name.to_sym)
        end

        form_name_item = nil
        name = "undefined"
        unless form.name.nil?
        name = form.name unless form.name.empty?
        end
        form_name_item = self.appendItem(form_item, name, nil, nil) 

        unless form_name_item.nil?
          self.setItemData(form_name_item, form)
          form.fields.each do |ff|
            form_field_item = self.appendItem(form_name_item, ff.name, nil, nil)
            self.setItemData(form_field_item, ff)

          end
          form.buttons.each do |fb|
            form_field_item = self.appendItem(form_name_item, fb.name, nil, nil)
            self.setItemData(form_field_item, fb)
          end
        end

        unless form_item.nil?
          form_item.text = "#{node_name} (#{form_item.numChildren})"
        end

      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end
    end
  # namespace end
  end
end
