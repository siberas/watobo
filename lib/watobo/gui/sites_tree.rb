#require 'qcustomize.rb'

# @private 
module Watobo#:nodoc: all
  module Gui
    class SitesTree < FXTreeList
      attr_accessor :project

      include Watobo::Constants
      include Watobo::Gui::Icons
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def reload()
        self.clearItems

        Watobo::Chats.each do |chat|
          addChat(chat)
        end

      # @interface.updateRequestTable(@project)
      end

      def refresh_tree()
        self.clearItems

        Watobo::Chats.each do |chat|
          addChat(chat)
        end

      # @interface.updateRequestTable(@project)
      end

      def expandFullTree(item)
        self.expandTree(item)
        item.each do |c|
          expandFullTree(c) if !self.itemLeaf?(c)
        end
      end

      def useSmallIcons()
        small_font = FXFont.new(getApp(), "helvetica", GUI_SMALL_FONT_SIZE)
        small_font.create
        @folderIcon = ICON_FOLDER_SMALL
        @reqIcon = ICON_REQUEST_SMALL
        @siteIcon= ICON_SITE_SMALL
        
        @icon_vuln = ICON_VULN_SMALL
        @icon_vuln_bp = ICON_VULN_BP_SMALL
        @icon_vuln_low = ICON_VULN_LOW_SMALL
        @icon_vuln_medium = ICON_VULN_MEDIUM_SMALL
        @icon_vuln_high = ICON_VULN_HIGH_SMALL
        @icon_vuln_critical = ICON_VULN_CRITICAL_SMALL
        
         @icon_info = ICON_INFO_SMALL
        @icon_info_info = ICON_INFO_INFO_SMALL
        @icon_hints_info = ICON_INFO_INFO_SMALL
        
        @icon_hints = ICON_HINTS_SMALL
        
        
        self.font = small_font
        reload()
      end

      def useRegularIcons()
        regular_font = FXFont.new(getApp(), "helvetica", GUI_REGULAR_FONT_SIZE)
        regular_font.create
        # Findings Tree Icons
        @folderIcon = ICON_FOLDER
        @reqIcon = ICON_REQUEST
        @siteIcon= ICON_SITE
        
        

        # Findings Tree Icons
        @icon_vuln = ICON_VULN
        @icon_vuln_bp = ICON_VULN_BP
        @icon_vuln_low = ICON_VULN_LOW
        @icon_vuln_medium = ICON_VULN_MEDIUM
        @icon_vuln_high = ICON_VULN_HIGH
        @icon_vuln_critical = ICON_VULN_CRITICAL
         @icon_info = ICON_INFO
        @icon_info_info = ICON_INFO_INFO
        @icon_hints_info = ICON_INFO_INFO

        @icon_hints = ICON_HINTS
        
        self.font = regular_font
        reload()
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

      def hideDomain(domain_filter)
        # @interface.default_settings[:domain_filters].push domain_filter
        # @interface.updateTreeLists()
      end
      
    
      def addFindings4Chat(item, chat)
        cpath = chat.request.path
        csite = chat.request.site
        Watobo::Findings.each do |fid, finding|
          if finding.details.has_key? :chat_id && finding.details[:chat_id] == chat.id
            addFindingItem(item, finding)
          elsif csite == finding.request.site and cpath == finding.request.path
            addFindingItem(item, finding)
          end
          
        end
        true
      end

      def addFindingItem(item, finding)
        begin          
          case finding.details[:type]
            when FINDING_TYPE_INFO
              finding_type = "Info"
              icon = @icon_info_info

            when FINDING_TYPE_HINT
              finding_type = "Hints"
              icon = @icon_hints_info

            when FINDING_TYPE_VULN
              finding_type = "Vulnerabilities"
              icon = @icon_vuln_bp
              
              if finding.details[:rating] == VULN_RATING_LOW
              icon = @icon_vuln_low
              #  puts "low-rating-vuln"
              end
              if finding.details[:rating] == VULN_RATING_MEDIUM
              icon = @icon_vuln_medium
              end
              if finding.details[:rating] == VULN_RATING_HIGH
              icon = @icon_vuln_high
              end
              if finding.details[:rating] == VULN_RATING_CRITICAL
              icon = @icon_vuln_critical
              end
            end

              class_item = self.findItem(finding.details[:class], item, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP|SEARCH_PREFIX)
              if not class_item or class_item.parent != item
                class_item = self.appendItem(item, finding.details[:class], icon, icon)
                self.setItemData(class_item, :finding_class )
              end
              title_item = self.findItem(finding.details[:title], class_item, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP)
              if not title_item or title_item.parent != class_item
                title_item = self.appendItem(class_item, finding.details[:title], nil, nil)
                self.setItemData(title_item, finding )
              # puts finding.details[:title]
              end
        rescue => bang
          puts "!ERROR: could not add finding to tree"
          puts bang
          puts bang.backtrace if $DEBUG

        end
      end

      def addChat(chat)
        if @show_scope_only == true
           return false unless Watobo::Scope.match_site?(chat.request.site)
        end 
        @tree_filters[:response_status].each do |rf|
        #puts "#{chat.response.status} / #{rf}"
          return false if chat.response.status =~ /#{rf}/
        end
        addChatItem(chat)
      end

      # end
      def addChatItem(chat)

        site = self.findItem(chat.request.site, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

        if not site then
          # found new site
          site = self.appendItem(nil, chat.request.site, @siteIcon, @siteIcon)
          #site = @findings_tree.moveItem(project.first,project,site)
          self.setItemData(site, :item_type_site)

        end

        @quick_filter[site.object_id] ||= []
        @quick_filter[site.object_id].push chat

        folder_parent = site
        #puts "ADD_REQUEST: #{chat.request.first}"
        dir = chat.request.dir

        if dir != "" then
          #puts "Check Folder: #{chat.request.path} - #{chat.request.site}" if path =~ /jump/
          folders = dir.split('/')
          folders.each do |folder_name|
          #   puts "search for folder #{folder_name}"
            folder_item = nil
            folder_parent.each do |c|
              folder_item = c if c.to_s == folder_name
            end
            #folder_item = self.findItem(folder_name, folder_parent, SEARCH_FORWARD|SEARCH_WRAP)
            if folder_item.nil? then
              #folder_item = self.appendItem(folder_parent, folder_name, @folderIcon, @folderIcon)
              folder_item = self.insertItem(folder_parent.first, folder_parent, folder_name, @folderIcon, @folderIcon)
              self.setItemData(folder_item, :item_type_folder)

            #     puts "added folder #{folder_name} to #{folder_parent} for site #{chat.request.site}"
            end
            @quick_filter[folder_item.object_id] ||= []
            @quick_filter[folder_item.object_id].push chat
            folder_parent = folder_item
          end
        end
        ml = 25
        fext = chat.request.file_ext
        element = "/" + fext.slice(0, ml)
        element += "..." if fext.length > ml

        item = nil
        folder_parent.each do |c|
          item = c if c.to_s == element
        end

        if item.nil?
        # puts item.text.methods.sort

        # puts "added file #{element} to #{folder_parent} for site #{chat.request.site}" if chat.request.url =~ /series60/i
        new_item = self.appendItem(folder_parent, element, @reqIcon, @reqIcon)
        #   self.textColor = FXColor::Red
        self.setItemData(new_item, chat)
        @quick_filter[new_item.object_id] ||= []
        #puts new_item.class
        @quick_filter[new_item.object_id].push chat
        
        # also add findings here
        # TODO: addFindings4Chat takes far too long here. instead create menue item to load findings manually
        # addFindings4Chat(new_item, chat)
        
        
        end

      end

      def initialize(parent, interface, project)
        @project = project
        @interface = interface
        @parent = parent
        @quick_filter = Hash.new
        @show_scope_only = false

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
        
        useRegularIcons()
        #    session_leaf = self.appendItem(nil, @session_name, @projectIcon, @projectIcon)

        self.connect(SEL_COMMAND) do |sender, sel, item|
          url_parts = []
          #  p = item
          if self.itemLeaf?(item)
          
              begin
                if item.data.is_a? Watobo::Chat
                  #if item.data.class.to_s =~ /Qchat/
                  #@interface.show_chat(item.data)
                  notify(:show_chat, item.data)
                #end
                chat = item.data
                #         url_parts.unshift chat.request.file_ext
                #         p = item.parent
                end
                
                if item.data.is_a? Watobo::Finding
                  #puts "* finding clicked"
                    #@interface.show_vuln(item.data)
                    notify(:vuln_click, item.data)
                  end
              rescue => bang
              #  puts bang
              #  puts bang.backtrace if $DEBUG
              #puts "!!! Error: could not show selected tree item"
              end
            end
          
          #elsif item.data == :item_type_folder||:item_type_site then
          
          # if !p.nil?
          #   while p.parent
          #    url_parts.unshift p.text.sub(/^\//,'')
          #    p = p.parent
          #  end
          #end
          #   url_parts.unshift p
          #   filter = url_parts.join("/")
          #   puts @quick_filter.keys.join("\n")
          #   puts "===="
          #   puts item
          #   puts "===="
            getApp().beginWaitCursor do
            notify(:show_conversation, @quick_filter[item.object_id]) if @quick_filter[item.object_id]
        #  notify(:apply_site_filter, filter)
          end
        end

        self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          exclude_site = nil
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|

              target = FXMenuCheck.new(menu_pane, "show scope only" )
              target.check = @show_scope_only

              target.connect(SEL_COMMAND) { |tsender, tsel, titem|
                @show_scope_only = tsender.checked?
                reload() if @project
              }

              exclude_submenu = FXMenuPane.new(self) do |sub|
                ["404", "302"].each do |rc|
                  target = FXMenuCheck.new(sub, "#{rc} Status" )

                  target.check = @tree_filters[:response_status].include? rc

                  target.connect(SEL_COMMAND) { |tsender, tsel, titem|
                    
                    rs = tsender.to_s.slice(/\d+/)
                    unless @tree_filters[:response_status].include? rs
                      @tree_filters[:response_status].push rs
                    else
                      @tree_filters[:response_status].delete rs
                    end
                    reload() if @project
                  }
                end
              end
              FXMenuCascade.new(menu_pane, "Hide", nil, exclude_submenu)

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

                if data == :item_type_site then
                  FXMenuSeparator.new(menu_pane)

                  FXMenuCommand.new(menu_pane, "add site to scope" ).connect(SEL_COMMAND) {

                    notify(:add_site_to_scope, item.to_s)
                  }

                elsif data.is_a? Watobo::Chat

                  FXMenuSeparator.new(menu_pane)
                  doManual = FXMenuCommand.new(menu_pane, "Manual Request.." )

                  doManual.connect(SEL_COMMAND) {
                    if item.data
                    @interface.open_manual_request_editor(item.data)
                    end

                  }
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
