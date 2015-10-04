require 'fox16'

include Fox

# @private 
module Watobo#:nodoc: all
  module Gui
    
    
    class ScopeDetailsFrame < FXVerticalFrame
      
      #   def fxMessageBox()
      #   FXMessageBox.information(self, MBOX_OK, "Wrong Signature Format", "Signature Format is wrong. Must be a valid regular expression, e.g.(<Regex>) <^Location.*action=logout>")  
      # end
      
      def getDetails
        d = Hash.new
        d[:root_path] = @rootpath_dt.value
        path_array = []
        @expath_list.each do |p|
          path_array.push p.data
        end
        d[:excluded_paths] = path_array
        d
      end
      
      def removePattern(list_box, pattern)
        index = list_box.currentItem
        if  index >= 0
          list_box.removeItem(index)
        end
      end
      
      def addPattern(list_box, pattern)   
        if pattern != "" then
          pattern_ok, *error = Watobo::Utils.checkRegex(pattern)
          if pattern_ok == true
            item = list_box.appendItem("#{pattern}")
            list_box.setItemData(item, pattern)
            list_box.sortItems()
            
          else
            FXMessageBox.information(self, MBOX_OK, "Wrong Path Format", "Path must be a Regex!!!\nError: #{error.join('\n')}")
          end
        end
      end
      
      def updateFrame(details)
        @rootpath_dt.value = details[:root_path]
        @rootpath_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        details[:excluded_paths].each do |p|
          addPattern(@expath_list, p)
        end
      end
      
      def initialize(parent, details=nil)
        
        @rootpath_dt = FXDataTarget.new('')
        @expath_dt = FXDataTarget.new('')
        
        
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        # main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_NONE, :padding => 0)
        title_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        title = FXLabel.new(title_frame, "Site:", :opts => LAYOUT_TOP)
        title = FXLabel.new(title_frame, "#{details[:site]}")
        title.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        #
        #   ROOT PATH BOX
        gbframe = FXGroupBox.new(self, "Root Path", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #text_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :padding =>0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "The Root Path defines the application root of the site. " +
         "Only URLs which include the Root Path will be tested during a scan." +
         "\nSetting the Root Path to 'myapp', only URLs that begin with http://#{details[:site]}/myapp/ will be tested."
        fxtext.setText(text)
        
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_NONE)
        FXLabel.new(input_frame,"Root Path (RegEx):")
        @rootpath_field = FXTextField.new(input_frame, 0, :target => @rootpath_dt, :selector => FXDataTarget::ID_VALUE, :opts => LAYOUT_FILL_X|TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
        
        #
        # EXCLUDED
        
        gbframe = FXGroupBox.new(self, "Excluded Path's", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "URLs which match a pattern will not be tested during a scan."
        fxtext.setText(text)
        input_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X)
        @expath_field = FXTextField.new(input_frame, 20, :target => @expath_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @remExPath = FXButton.new(input_frame, "Remove" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @addExPath = FXButton.new(input_frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)        
        
        list_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
        @expath_list = FXList.new(list_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @expath_list.numVisible = 5
        
        @expath_list.connect(SEL_COMMAND){ |sender, sel, item|
          @expath_dt.value = sender.getItemText(item)
          @expath_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @remExPath.connect(SEL_COMMAND){ |sender, sel, item|
          removePattern(@expath_list, @expath_dt.value) if @expath_dt.value != ''
          @expath_dt.value = ''
          @expath_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        @addExPath.connect(SEL_COMMAND){ |sender, sel, item|
          
          addPattern(@expath_list, @expath_dt.value) if @expath_dt.value != ''
          @expath_dt.value = ''
          @expath_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        @expath_dt.connect(SEL_COMMAND){ |sender, sel, item|
          
          addPattern(@expath_list, @expath_dt.value) if @expath_dt.value != ''
          @expath_dt.value = ''
          @expath_field.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        }
        
        updateFrame(details)
        self.update
      end
    end
    
    
    
    class EditScopeDetailsDialog < FXDialogBox
      
      attr :details
      
      include Responder
      
      def onAccept(sender, sel, event)
        @details = @scopeDetailsFrame.getDetails()
        root_path_ok, *error = Watobo::Utils.checkRegex(@details[:root_path])
        if root_path_ok == true
          getApp().stopModal(self, 1)
          self.hide()
          return 1
        else
          FXMessageBox.information(self, MBOX_OK, "Wrong Root Path Format", "Root Path must be a Regex!!!\nError: #{error.join('\n')}")
        end
        
      end
      
      def initialize(owner, details)
        
        super(owner, "Scope Details", 
        :opts => DECOR_TITLE|DECOR_BORDER|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 350, :height => 500)
        
        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
        
        @details = (details.is_a? Hash) ? details : Hash.new
        
        @root_path = FXDataTarget.new('')
        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_X|FRAME_NONE, :padding => 0)
        @scopeDetailsFrame = ScopeDetailsFrame.new(main_frame, details)
        
        button_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
        accept = FXButton.new(button_frame, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        accept.enable
        # Cancel
        FXButton.new(button_frame, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end
    end
    
    class DefineScopeFrame < FXVerticalFrame
      
      def onDeselectAll(sender, sel, item)        
        @cb_sites.each_key do |site|        
          @cb_sites[site].setCheck(false)  
          @edit_btns[site].disable
        end
        @sel_all_btn.setFocus()
        @sel_all_btn.setDefault()
        
      end
      
      def onSelectAll(sender, sel, item)
        sites = []
        @cb_sites.each_key do |site|
          @cb_sites[site].setCheck(true)
          @edit_btns[site].enable
        end
        @desel_all_btn.setFocus()
        @desel_all_btn.setDefault()
      end
      
      def editSiteDetails(site)
        dlg = EditScopeDetailsDialog.new(self, @scope[site])
        
        if dlg.execute != 0
          @scope[site].update dlg.details
          puts dlg.details.to_yaml
        end
      end
      
      def getScope()
        scope = Hash.new
        @cb_sites.keys.each do |site|
          @scope.delete(site) if !@cb_sites[site].checked?
          # scope[site] = @scope[site] if @cb_sites[site].checked?
        end
        return @scope
      end
      
      def updateFrame()
        @scope.each do |site, scope|
          next if @cb_sites[site].nil? 
          @cb_sites[site].setCheck(scope[:enabled])
          @cb_sites[site].checked? ? @edit_btns[site].enable : @edit_btns[site].disable
        end
        
      end
      
      def setScope(scope)
        @scope = scope
        Watobo::Scope.each do |site, scope_def|         
          @scope[site].update @scope[site] if !@scope[site].nil?         
        end
        updateFrame()
      end
      
      def initialize(owner, opts)
        super(owner, :opts => opts, :padding => 0)
        
       # @scope = Hash.new
       # @scope = YAML.load(YAML.dump(scope)) if scope.is_a? Hash
       @scope = YAML.load(Watobo::Scope.to_yaml)
       
        @cb_sites = Hash.new
        @edit_btns = Hash.new
        
        title = FXLabel.new(self, "Target Scope")
        info_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        title.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        
        scope_text =<<'EOF'
The target scopes affects primarly the 
behaviour all WATOBO scanner tools. 
Click the appropriate edit-button for more 
 detailed settings.
EOF
        btn = FXButton.new(info_frame, scope_text,
                           :opts => LAYOUT_FILL_X|LAYOUT_FIX_HEIGHT, :height => 90)
        #btn.font = @font
        #btn.backColor = FXColor::White
        btn.justify = JUSTIFY_LEFT
        
        quickFilterFrame = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        FXLabel.new(quickFilterFrame, "Filter:", nil, :opts => LAYOUT_TOP|JUSTIFY_RIGHT)
        filter_regexp = FXTextField.new(quickFilterFrame, 25, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_LEFT)
        filter_btn = FXButton.new(quickFilterFrame, "apply")

        filter_regexp.connect(SEL_COMMAND){ list_sites(filter_regexp.text.strip) }
        filter_btn.connect(SEL_COMMAND){ list_sites(filter_regexp.text.strip) }


                
        quickSelectFrame = FXHorizontalFrame.new(self, LAYOUT_FILL_X)
        @sel_all_btn = FXButton.new(quickSelectFrame, "Select All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @sel_all_btn.connect(SEL_COMMAND, method(:onSelectAll))
        
        @sel_all_btn.setFocus()
        @sel_all_btn.setDefault()
        
        @desel_all_btn = FXButton.new(quickSelectFrame, "Deselect All", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_FILL_X)
        @desel_all_btn.connect(SEL_COMMAND, method(:onDeselectAll)) 
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :padding => 0)
        
        sitesArea = FXScrollWindow.new(frame, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @sitesFrame = FXVerticalFrame.new(sitesArea, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        
        list_sites
        
        updateFrame()
      end
      
      private
      
      def list_sites(p='.*')
        @cb_sites.clear  
        @edit_btns.clear
        # clear container
        @sitesFrame.each_child do |c|
          @sitesFrame.removeChild c
        end
        @sitesFrame.recalc
        @sitesFrame.update
        
        pattern = p
        pattern = '.*' if p.nil? or p.empty?
        
        sites = Watobo::Chats.sites()
        sites.compact!
        
        sites.sort.each do |site|     
          next unless site =~ /#{pattern}/
          site_frame = FXHorizontalFrame.new(@sitesFrame, :opts => LAYOUT_FILL_X)
          b = FXCheckButton.new(site_frame, site, nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
          eb = FXButton.new(site_frame, "edit..", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT)
          @edit_btns[site] = eb
          site_frame.create if self.parent.created?
          
          b.connect(SEL_COMMAND){
            b.checked? ? @edit_btns[site].enable : @edit_btns[site].disable
            @scope[site][:enabled] = true
          }
          
          
          @cb_sites[site] = b  
          b.setCheck(false)
          scope_details = {
            :site => site,
            :enabled => false,
            :root_path => '',
            :excluded_paths => [],
            #:exclude_pattern => []
          }
          
          if !@scope[site]
          @scope[site] = scope_details 
        else
          @scope[site][:enabled] = true
          end
          
          
          eb.connect(SEL_COMMAND){
            editSiteDetails(site)            
          }
          
        end
        @sitesFrame.recalc
        @sitesFrame.update
      end
      
      
    end #EOC
    #--
  end
end


if __FILE__ == $0
  require '../utils/check_regex'
  
  class TestGui < FXMainWindow
    
    def initialize(app)
      # Call base class initializer first
      super(app, "Test Application", :width => 800, :height => 600)
      frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
      
      pbButton = FXButton.new(frame, "create FXProgressBar",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,:padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
      
      @scope_details = {
        :site => "127.0.0.1",
        :enabled => false,
        :root_path => '',
        :excluded_paths => [],
        #:exclude_pattern => []
      }
      pbButton.connect(SEL_COMMAND) {
        
        dlg = Watobo::Gui::EditScopeDetailsDialog.new(self,scope_details)
        
        if dlg.execute != 0
          puts dlg.details.to_yaml
        end  
      }
    end
    # Create and show the main window
    def create
      super                  # Create the windows
      show(PLACEMENT_SCREEN) # Make the main window appear
      dlg = Watobo::Gui::EditScopeDetailsDialog.new(self, @scope_details)
      
      if dlg.execute != 0
        puts dlg.details.to_yaml
      end  
    end
  end
  application = FXApp.new('LayoutTester', 'FoxTest')  
  TestGui.new(application)
  application.create
  application.run
end
