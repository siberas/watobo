#require 'qcustomize.rb'

# @private 
module Watobo #:nodoc: all
  module Plugin
    class Sniper
      class Gui
        class ResultTree < FXTreeList
          include Watobo::Constants
          include Watobo::Gui::Icons

          attr_accessor :project

          def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
          end

          def expandFullTree(item)
            @expandeds = []
            self.expandTree(item)
            item.each do |c|
              expandFullTree(c) if !self.itemLeaf?(c)
            end
          end

          def collapseFullTree(item)
            @expandeds = []
            self.collapseTree(item)
            item.each do |c|
              collapseFullTree(c) if !self.itemLeaf?(c)
            end
          end

          def hidden?(finding)
            return true if @hide_false_positives == true and finding.false_positive?
            false
          end


          def reload()
            self.clearItems
            @findings.clear
            Watobo::Findings.each do |fid, finding|
              addFinding(finding)
            end
            expand_findings
            @expandeds.each do |t|
              site, text = t.split("|")
              if (site = self.findItem(site, nil, SEARCH_FORWARD|SEARCH_NOWRAP))
                if (node = self.findItem(text, site, SEARCH_FORWARD|SEARCH_NOWRAP))
                  self.expandTree(node)
                else
                  @expandeds.delete t
                end
              end
            end
          end

          def useRegularIcons()

            regular_font = FXFont.new(getApp(), "helvetica", GUI_REGULAR_FONT_SIZE)
            regular_font.create
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

            @icon_project = ICON_PROJECT
            @icon_hints = ICON_HINTS
            self.font = regular_font
            reload()
          end

          def useSmallIcons
            small_font = FXFont.new(getApp(), "helvetica", GUI_SMALL_FONT_SIZE)
            small_font.create
            @icon_vuln = ICON_VULN_SMALL
            @icon_vuln_bp = ICON_VULN_BP_SMALL
            @icon_vuln_low = ICON_VULN_LOW_SMALL
            @icon_vuln_medium = ICON_VULN_MEDIUM_SMALL
            @icon_vuln_high = ICON_VULN_HIGH_SMALL
            @icon_vuln_critical = ICON_VULN_CRITICAL_SMALL
            @icon_info = ICON_INFO_SMALL
            @icon_info_info = ICON_INFO_INFO_SMALL
            @icon_hints_info = ICON_INFO_INFO_SMALL
            @icon_project = ICON_PROJECT_SMALL
            @icon_hints = ICON_HINTS_SMALL
            self.font = small_font
            reload()
          end

          def hideDomain(domain_filter)
            #@interface.default_settings[:domain_filters].push domain_filter
            #@interface.updateTreeLists
            #notify(:new_domain_filter, domain_filter)
          end

          def addFinding(finding)
            #  p "* add finding to tree"
            #  puts finding.details[:title]
            @findings[finding.details[:fid]] = finding
            if @show_scope_only == true
              addFindingItem(finding) if Watobo::Scope.match_site?(finding.request.site)
            else
              addFindingItem(finding)
            end

          end

          def addFindingItem(finding)
            begin

              site = nil
              # puts "add finding"
              if not hidden?(finding) then
                site = self.findItem(finding.request.site, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

                if not site then
                  # found new site
                  site = self.appendItem(nil, finding.request.site, @icon_project, @icon_project)
                  item = self.appendItem(site, "Vulnerabilities", @icon_vuln, @icon_vuln)
                  self.setItemData(item, :finding_type)
                  item = self.appendItem(site, "Hints", @icon_hints, @icon_hints)
                  self.setItemData(item, :finding_type)
                  item = self.appendItem(site, "Info", @icon_info, @icon_info)
                  self.setItemData(item, :finding_type)
                  #site = @findings_tree.moveItem(project.first,project,site)
                  self.setItemData(site, :item_type_site)

                end

                finding_type=""

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

                sub_tree = self.findItem(finding_type, site, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP)
                if sub_tree and sub_tree.parent == site and finding.details[:class]
                  class_item = nil

                  # don't use findItem here because of nested collisions
                  sub_tree.each do |c|
                    if c.text =~ /^#{Regexp.quote(finding.details[:class])}/
                      class_item = c
                    end
                  end
                  #class_item = self.findItem(finding.details[:class], sub_tree, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP|SEARCH_PREFIX)

                  if not class_item or class_item.parent != sub_tree
                    class_item = self.appendItem(sub_tree, finding.details[:class], icon, icon)
                    self.setItemData(class_item, :finding_class)
                  end
                  title_item = self.findItem(finding.details[:title], class_item, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP)
                  if not title_item or title_item.parent != class_item
                    title_item = self.appendItem(class_item, finding.details[:title], nil, nil)
                    self.setItemData(title_item, :title)
                    # puts finding.details[:title]
                  end
                  #   puts title_item
                  resource = finding.request.path_ext

                  request_item = self.findItem(resource, title_item, SEARCH_FORWARD|SEARCH_IGNORECASE|SEARCH_NOWRAP)
                  if not request_item or request_item.parent != title_item
                    text = "/" + resource
                    request_item = self.appendItem(title_item, text)
                    self.setItemData(request_item, finding)
                  end

                  #
                  unless class_item.text =~ / \(\d+\)$/
                    class_item.text = class_item.text + " (#{class_item.numChildren})"
                  else
                    class_item.text = class_item.text.gsub(/ \(\d+\)$/, " (#{class_item.numChildren})")
                  end
                end

              end
            rescue => bang
              puts "!ERROR: could not add finding to tree"
              puts bang
              puts bang.backtrace if $DEBUG

            end
          end

          def initialize(parent)
            @parent = parent
            @findings = Hash.new
            @show_scope_only = false
            @hide_false_positives = false
            @clipboard = ""
            @expandeds = []

            @event_dispatcher_listeners = Hash.new

            super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT)

            #useRegularIcons()

            @filtered_domains = Hash.new # domains which already have been filtered

            self.connect(SEL_CLIPBOARD_REQUEST) do
              setDNDData(FROM_CLIPBOARD, FXWindow.stringType, Fox.fxencodeStringData(@clipboard.to_s))
            end

            self.connect(SEL_EXPANDED) do |sender, sel, item|
              parent = item
              while parent.parent
                parent = parent.parent
              end
              unless parent.nil? or item.nil?
                node = "#{parent.text}|#{item.text}"
                @expandeds << node
              end
            end

            self.connect(SEL_COLLAPSED) do |sender, sel, item|
              parent = item
              while parent.parent
                parent = parent.parent
              end
              node = "#{parent.text}|#{item.text}"
              @expandeds.delete node
            end

            self.connect(SEL_COMMAND) do |sender, sel, item|
              if self.itemLeaf?(item)
                getApp().beginWaitCursor do
                  begin
                    if item.data
                      if item.data.is_a? Watobo::Finding
                        #@interface.show_vuln(item.data)
                        notify(:vuln_click, item.data)
                      end
                    end
                  rescue => bang
                    puts "!!! Error: could not show selected finding"
                    puts bang
                  end
                end
              elsif item.data == :title then
                #@interface.show_vuln(item.first.data) if item.first.data
                notify(:vuln_click, (item.first.data)) if item.first.data
              end
            end

            self.connect(SEL_DOUBLECLICKED) do |sender, sel, item|
              if self.itemLeaf?(item)
                begin
                  puts item.data.class
                  if item.data.is_a? Watobo::Finding
                    #TODO: show vulnerability details
                    # @interface.showFindingInfo(item.data)
                    notify(:finding_click, item.data)
                  else
                    puts item.data.class.to_s
                  end
                rescue => bang
                  puts "!!! Error: could not show selected finding"
                  puts bang
                end
              end
            end

            self.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
              unless event.moved?
                FXMenuPane.new(self) do |menu_pane|
                  item = sender.getItemAt(event.win_x, event.win_y)
                  unless item.nil?

                    data = self.getItemData(item)


                    unless self.itemLeaf?(item)
                      FXMenuCommand.new(menu_pane, "expand tree").connect(SEL_COMMAND) {
                        expandFullTree(item)
                      }

                      FXMenuCommand.new(menu_pane, "collapse tree").connect(SEL_COMMAND) {
                        self.collapseFullTree(item)
                      }
                      FXMenuSeparator.new(menu_pane)
                    end
                  end
                  target = FXMenuCheck.new(menu_pane, "show scope only")

                  target.check = @show_scope_only

                  target.connect(SEL_COMMAND) { |ts, sl, it|
                    @show_scope_only = ts.checked?
                    reload
                  }

                  target = FXMenuCheck.new(menu_pane, "hide false-positives")

                  target.check = @hide_false_positives

                  target.connect(SEL_COMMAND) { |ts, sl, it|
                    @hide_false_positives = ts.checked?
                    reload
                  }


                  unless item.nil?

                    data = self.getItemData(item)

                    FXMenuSeparator.new(menu_pane) unless data == :finding_type


                    if data == :item_type_site then
                      # FXMenuSeparator.new(menu_pane)
                      FXMenuCommand.new(menu_pane, "add site to scope").connect(SEL_COMMAND) {
                        #notify(:add_site_to_scope, item.to_s)
                        Watobo::Scope.add item.to_s
                        reload
                      }
                      #
                    elsif data == :title
                      findings = []
                      item.each do |ft|
                        f = self.getItemData(ft)
                        findings << f if f.is_a? Watobo::Finding
                      end

                      fp_submenu = FXMenuPane.new(self) do |sub|


                        target = FXMenuCommand.new(sub, "Set False Positive")
                        target.connect(SEL_COMMAND) {

                          # puts "* False Positive #{findings.length}"

                          # remember parent node to expand it later
                          fclass = item.parent.text
                          fcat = item.parent.parent.text
                          fsite = item.parent.parent.parent.text

                          puts ">> #{fsite} - #{fcat} - #{fclass} (#{fclass.object_id})"

                          notify(:set_false_positive, findings)

                          reload

                          site_item = cat_item = class_item = nil
                          site_item = self.findItem(fsite, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

                          unless site_item.nil?
                            self.expandTree(site_item)
                            cat_item = self.findItem(fcat, site_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end

                          unless cat_item.nil?
                            self.expandTree(cat_item)
                            class_item = self.findItem(fclass, cat_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end


                          unless class_item.nil?
                            puts "Expanding #{class_item} (#{class_item.object_id})-> #{cat_item} -> #{site_item}"
                            self.expandTree(class_item)
                          else
                            puts "Could not find tree item for #{class_item} (#{class_item.object_id})-> #{cat_item} -> #{site_item}"
                          end
                        }
                        target = FXMenuCommand.new(sub, "Unset False Positive")
                        target.connect(SEL_COMMAND) {
                          fclass = item.parent.text
                          fcat = item.parent.parent.text
                          fsite = item.parent.parent.parent.text

                          notify(:unset_false_positive, findings)
                          reload
                          site_item = cat_item = class_item = nil
                          site_item = self.findItem(fsite, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

                          unless site_item.nil?
                            self.expandTree(site_item)
                            cat_item = self.findItem(fcat, site_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end

                          unless cat_item.nil?
                            self.expandTree(cat_item)
                            class_item = self.findItem(fclass, cat_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end


                          unless class_item.nil?
                            puts "Expanding #{class_item} (#{class_item.object_id})-> #{cat_item} -> #{site_item}"
                            self.expandTree(class_item)
                          else
                            puts "Could not find tree item for #{class_item} (#{class_item.object_id})-> #{cat_item} -> #{site_item}"
                          end
                        }

                        FXMenuSeparator.new(sub)

                        FXMenuCommand.new(sub, "Purge - NO UNDO!").connect(SEL_COMMAND) {
                          notify(:purge_findings, findings)
                          reload
                        }
                      end
                      FXMenuCascade.new(menu_pane, "All \"#{item}\"", nil, fp_submenu)

                      FXMenuSeparator.new(menu_pane)
                      info = FXMenuCommand.new(menu_pane, "Details...")
                      info.connect(SEL_COMMAND) {
                        #@interface.showFindingDetails(item.data)}
                        notify(:show_finding_details, findings.first)
                      }

                    elsif data == :finding_class
                      #puts "FINDING_CLASS"
                      # COPY SUBMENU
                      findings = []
                      item.each do |c|
                        c.each do |ft|
                          f = self.getItemData(ft)
                          findings << f if f.is_a? Watobo::Finding
                        end

                      end

                      fp_submenu = FXMenuPane.new(self) do |sub|

                        target = FXMenuCommand.new(sub, "Copy URLs")
                        target.connect(SEL_COMMAND) {

                          urls = []
                          findings.each do |f|
                            proto = f.request.proto
                            site = f.request.site
                            path = f.request.path
                            urls << "#{proto}://#{site}/#{path}"
                          end
                          types = [FXWindow.stringType]
                          if acquireClipboard(types)
                            @clipboard = urls.uniq.join("\n")
                          end
                        }

                        target = FXMenuCommand.new(sub, "Set False Positive")
                        target.connect(SEL_COMMAND) {

                          fcat = item.parent.text
                          fsite = item.parent.parent.text

                          notify(:set_false_positive, findings)
                          reload
                          site_item = cat_item = class_item = nil
                          site_item = self.findItem(fsite, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

                          unless site_item.nil?
                            self.expandTree(site_item)
                            cat_item = self.findItem(fcat, site_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end

                          unless cat_item.nil?
                            self.expandTree(cat_item)
                          end

                        }
                        target = FXMenuCommand.new(sub, "Unset False Positive")
                        target.connect(SEL_COMMAND) {
                          fcat = item.parent.text
                          fsite = item.parent.parent.text
                          notify(:unset_false_positive, findings)
                          reload
                          site_item = cat_item = class_item = nil
                          site_item = self.findItem(fsite, nil, SEARCH_FORWARD|SEARCH_IGNORECASE)

                          unless site_item.nil?
                            self.expandTree(site_item)
                            cat_item = self.findItem(fcat, site_item, SEARCH_FORWARD|SEARCH_IGNORECASE)
                          end

                          unless cat_item.nil?
                            self.expandTree(cat_item)
                          end
                        }

                        FXMenuSeparator.new(sub)
                        FXMenuCommand.new(sub, "Purge - NO UNDO!").connect(SEL_COMMAND) {

                          puts "* purge findings #{findings.length}"

                          notify(:purge_findings, findings)
                          reload
                        }

                      end
                      FXMenuCascade.new(menu_pane, "All \"#{item}\"", nil, fp_submenu)

                      FXMenuSeparator.new(menu_pane)
                      info = FXMenuCommand.new(menu_pane, "Details...")
                      info.connect(SEL_COMMAND) {
                        #@interface.showFindingDetails(item.data)}
                        notify(:show_finding_details, findings.first)
                      }

                    elsif data.is_a? Watobo::Finding then
                      FXMenuCommand.new(menu_pane, "Copy URL").connect(SEL_COMMAND) {
                        types = [FXWindow.stringType]
                        if acquireClipboard(types)
                          @clipboard = item.data.request.url.to_s
                        end

                      }
                      # FXMenuSeparator.new(menu_pane)
                      doManual = FXMenuCommand.new(menu_pane, "Manual Request..")
                      doManual.connect(SEL_COMMAND) {
                        # @interface.open_manual_request_editor(item.data)
                        notify(:open_manual_request, item.data)

                      }
                      info = FXMenuCommand.new(menu_pane, "Details...")
                      info.connect(SEL_COMMAND) {
                        #@interface.showFindingDetails(item.data)}
                        notify(:show_finding_details, item.data)
                      }
                    end

                  end
                  menu_pane.create
                  menu_pane.popup(nil, event.root_x, event.root_y)
                  app.runModalWhileShown(menu_pane)
                end
              end
            end
          end

          private

          def expand_findings()
            self.each do |site|
              expandTree site
              %w(Vulnerabilities Hints Info).each do |item|
                f = self.findItem(item, site, SEARCH_FORWARD|SEARCH_IGNORECASE)
                expandTree(f) unless site.nil?
              end
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

        class ResultFrame < FXVerticalFrame

          def set_targets

          end

          def update
            
          end

          def initialize(parent, opts)
            super(parent, opts)

            @settings = Watobo::Plugin::Sniper::Settings

            result_gb = FXGroupBox.new(self, "Results", FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            @result_tree = ResultTree.new(result_gb) #, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FIX_WIDTH, :width => 450)
        # namespace end
          end
        end

      end
    end

  end
end
