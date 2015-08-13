#require 'qcustomize.rb'

# @private 
module Watobo#:nodoc: all
  module Plugin
    class AEM
      class Gui
    class TreeView < FXTreeList
      
      include Watobo::Constants
      include Watobo::Gui::Icons
      
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clear()
        @results = []
        self.clearItems
      end

      #def refresh_tree()
      #  self.clearItems

        #Watobo::Chats.each do |chat|
        #  addChat(chat)
        #end

      # @interface.updateRequestTable(@project)
      #end

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



      def add(result)        
        addItem(result)
      end
      
      def set_base_dir(url)
        url.gsub!(/^.*\/\//,'')
        subdirs = url.split '/'
        subdirs.shift
        item = nil
        subdirs.each do |d|
         # puts "* append #{d}"
          nxt = self.appendItem(item, d)#, @folderIcon, @folderIcon)              
          self.setItemData(nxt, :base_dir)
         # puts nxt.class
          item = nxt
        end
        
       # @base_dir = subdirs.join '/'
      end

      # end
      def addItem(result)
        #puts result
        url = "#{result[:url].to_s}"
        url.gsub!(/^.*\/\//,'')
        subdirs = url.split '/'
        subdirs.shift
        
        puts subdirs.join ' | '
        
        item = nil
        subdirs.each do |d|
          nxt = self.findItem(d, item, SEARCH_FORWARD)          
          break if nxt.nil?
          item = nxt 
        end
        
        unless item.nil? 
          unless subdirs.last == item.text
            new_item = self.appendItem(item, subdirs.last)#, @folderIcon, @folderIcon)              
            self.setItemData(new_item, result)
          end
        end
        
      end

      def initialize(parent)
        
        @parent = parent
        @quick_filter = Hash.new
        @show_scope_only = false
        
        @results = []

        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT)

        @event_dispatcher_listeners = Hash.new

        @projectIcon = ICON_PROJECT

        @folderIcon = ICON_FOLDER
        @reqIcon = ICON_REQUEST
        @siteIcon= ICON_SITE

        @filtered_domains = Hash.new # domains which already have been filtered

        @tree_filters = {
          :response_status => []
        }
        
        #    session_leaf = self.appendItem(nil, @session_name, @projectIcon, @projectIcon)

        self.connect(SEL_COMMAND) do |sender, sel, item|
          url_parts = []
          begin
            if item.data.is_a? Hash
               #if item.data.class.to_s =~ /Qchat/
               #@interface.show_chat(item.data)
                  notify(:show_info, item.data)
             end
                
          rescue => bang
              #  puts bang
              #  puts bang.backtrace if $DEBUG
              #puts "!!! Error: could not show selected tree item"
          end
          
          getApp().beginWaitCursor do
            notify(:show_conversation, @quick_filter[item.object_id]) if @quick_filter[item.object_id]
          end
        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          exclude_site = nil
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|

              target = FXMenuCheck.new(menu_pane, "test" )

              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)
              app.runModalWhileShown(menu_pane)

            end
          end
        end
      end

private

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
  end
end
