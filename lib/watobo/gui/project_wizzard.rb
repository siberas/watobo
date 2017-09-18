# @private 
module Watobo#:nodoc: all
  module Gui
    
    
    class NewProjectWizzard < FXDialogBox
      
      attr :selected_session_path
      attr :selected_project_path
      attr :new_session_name
      attr :new_project_name
      attr :project_name
      attr :session_name
      
      
      
      def workspace_dir
        return @workspace_dt.value  
      end
      
      def open_select_workspace_dt_dialog(sender, sel, ptr)
        workspace_dt = FXFileDialog.getOpenDirectory(self, "Select Workspace Directory", @workspace_dt.value)
        if workspace_dt != "" then
          if File.exist?(workspace_dt) then
            @workspace_dt.value = workspace_dt
            @workspace_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            updateProjectList(@workspace_dt.value)
            @newProjectButton.enable
          end
          
        end
      end
      
      def updateProjectList(workspace_dt)
        @projectList.clearItems
        
        if File.exist?(workspace_dt) then
          Dir.foreach(workspace_dt) do |file|
            #puts file
            if not file =~ /^\.{1,2}/ and File.ftype(File.join(workspace_dt,file)) == 'directory' then
              @projectList.appendItem(file)
            end
          end
        end
        
      #  puts "found #{@projectList.numItems} projects"
      end
      
      def updateSessionList(project_dir)
        @sessionList.clearItems
        Dir.foreach(project_dir) do |file|
          if not file =~ /^\.{1,2}/ and File.ftype(File.join(project_dir,file)) == 'directory' then
            @sessionList.appendItem(file)
          end
        end
     #   puts "found #{@sessionList.numItems} sessions"
      end
      
      
      def openProject(sender, sel, index)
        @selected_project_path = File.join(@workspace_dt.value, @projectList.getItemText(index))
        @new_project_name.value = @projectList.getItemText(index)
        @project_name = @projectList.getItemText(index)
        @projectCaption.text = "Project: #{@new_project_name.value}"
      #  puts @selected_project_path
        updateSessionList(@selected_project_path)
        @projectTextField.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @nextButton.enable
        @finishButton.disable
         @switcher.current = @switcher.current+1
        @backButton.enable
        @nextButton.disable if @switcher.current == @switcher.numChildren-1 
        setButtons(@switcher.current)
      end
      
      def onProjectSelect(sender, sel, index)
        @selected_project_path = File.join(@workspace_dt.value, @projectList.getItemText(index))
        @new_project_name.value = @projectList.getItemText(index)
        @project_name = @projectList.getItemText(index)
        @projectCaption.text = "Project: #{@new_project_name.value}"
      #  puts @selected_project_path
        updateSessionList(@selected_project_path)
        @projectTextField.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @nextButton.enable
        @finishButton.disable
       
      end
      
      def onSessionSelect(sender, sel, index)
        @selected_session_path = File.join(@selected_project_path, @sessionList.getItemText(index))
        @new_session_name.value = @sessionList.getItemText(index)
        @session_name = @new_session_name.value 
        #  @session_name = @sessionList.getItemText(index)
        @sessionTextField.handle(self, FXSEL(SEL_UPDATE, 0), nil)
       # puts @selected_session_path
        @finishButton.enable
      end
      
      def openSession(sender, sel, index)
        @selected_session_path = File.join(@selected_project_path, @sessionList.getItemText(index))
        @new_session_name.value = @sessionList.getItemText(index)
        @session_name = @new_session_name.value 
       # puts @selected_session_path
        self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
      end
      
      def createSession(sender, sel, event)
        begin
          if @new_session_name.value != '' then
            @session_name = @new_session_name.value 
            if File.exist?(@selected_project_path) then
              new_folder = File.join(@selected_project_path, @new_session_name.value)
              if File.exist?(new_folder) then
                puts "! folder already exists"
              else
                Dir.mkdir(new_folder)
                updateSessionList(@selected_project_path)
                new_session_index = @sessionList.findItem(@new_session_name.value)
                @session_name = @new_session_name.value
                
                new_session_item = @sessionList.selectItem(new_session_index)
                @sessionList.makeItemVisible(new_session_index)
                @selected_session_path = File.join(@selected_project_path, @session_name)
                
                # @new_session_name.value = ''
                @finishButton.enable
                @finishButton.setFocus()
                @finishButton.setDefault()
              end
            end
          end
        rescue => bang
          puts "!!!ERROR: could not create session"
          puts bang
          @finishButton.disable
        end
      end
      
      def createProject(sender, sel, event)
        begin
          if @new_project_name.value != '' then
            @project_name = @new_project_name.value
            if File.exist?(@workspace_dt.value) then
              new_folder = File.join(@workspace_dt.value, @new_project_name.value)
              if File.exist?(new_folder) then
                puts "! folder already exists"
              else
                Dir.mkdir(new_folder)
                @projectCaption.text = "Project: #{@new_project_name.value}"
                
                @selected_project_path = new_folder
                updateProjectList(@workspace_dt.value)
                new_project_index = @projectList.findItem(@new_project_name.value)
                new_project_item = @projectList.selectItem(new_project_index, true)
                @projectList.makeItemVisible(new_project_index)
                
                updateSessionList(@selected_project_path)
                @new_project_name.value = ''
                @nextButton.enable
                # had to disable setFocus on button, because it freezed the project name field
                #@nextButton.setFocus()
                @nextButton.setDefault()
                @finishButton.disable
              end
            else
              FXMessageBox.information(FXApp.instance, MBOX_OK, "No Workspace Selected!", "You need to select a workspace directory before you can start")
            end
          end
        rescue => bang
          puts "!!!ERROR: could not create project"
          puts bang
        end
      end
      
      
      def setButtons(index)
        case index
          when 0 
          # select project screen
          if @projectList.currentItem >= 0 and @projectList.itemSelected?(@projectList.currentItem)  then
            @nextButton.enable
          end        
          when 1
          # select session screen
          @sessionTextField.setFocus()
          @sessionTextField.setDefault()
          if @sessionList.currentItem >= 0 and @sessionList.itemSelected?(@sessionList.currentItem)  then
          #  puts "session selected"
          #  puts @sessionList.currentItem
            @finishButton.enable 
          end
        end
      end
      
      
      def initialize(parent, workspace_path=nil)
        # Invoke base class initialize function first
        #  super(parent, "New Project", DECOR_TITLE|DECOR_BORDER)
        super(parent, "New Project", DECOR_ALL)
        
        @selected_project_path = ''
        @new_project_name = FXDataTarget.new('')
        @new_session_name = FXDataTarget.new('')
        @workspace_dt = FXDataTarget.new('')
        @target_url = FXDataTarget.new('')
        @proxy = FXDataTarget.new('')
        
        @project_name = ''
        @session_name = ''
        
        @session_name = ''
        
        if workspace_path then
          if File.exist?(workspace_path) then
            @workspace_dt.value = workspace_path 
            
          else
            #  FXMessageBox.information(FXApp.instance, MBOX_OK, "No Workspace Selected!", "You need to select a workspace directory before you can start")
          end
        end
        
        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @switcher = FXSwitcher.new(base_frame,LAYOUT_FILL_X|LAYOUT_FILL_Y)   
        first_frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        workspace_path_form = FXHorizontalFrame.new(first_frame,
                                                    :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        FXLabel.new(workspace_path_form, "Workspace Directory:" )
        @workspace_text = FXTextField.new(workspace_path_form, 25,
                                          :target => @workspace_dt, :selector => FXDataTarget::ID_VALUE,
                                          :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)
        @workspace_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        browse_button=FXButton.new(workspace_path_form, "Change")
        browse_button.connect(SEL_COMMAND, method(:open_select_workspace_dt_dialog) )
        
        
        #
        # PROJECT SELECTION
        #
        #projectSelectionFrame = FXHorizontalFrame.new(first_frame, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        
        projectSelectionFrame = FXGroupBox.new(first_frame, "Select Project", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        
        projectSubSelection = FXVerticalFrame.new(projectSelectionFrame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        newProjectFrame = FXHorizontalFrame.new(projectSubSelection, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        FXLabel.new(newProjectFrame, "Project Name:" )
        @projectTextField = FXTextField.new(newProjectFrame, 25,
                                            :target => @new_project_name, :selector => FXDataTarget::ID_VALUE,
                                            :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
        @newProjectButton = FXButton.new(newProjectFrame, "New" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        @newProjectButton.disable if @workspace_dt.value == ''
        
        @new_project_name.connect(SEL_COMMAND, method(:createProject))
        @newProjectButton.connect(SEL_COMMAND, method(:createProject))
        
        projectListOuterFrame = FXVerticalFrame.new(projectSubSelection, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :padding => 0)
        @projectList = FXList.new(projectListOuterFrame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @projectList.numVisible = 14
        
        @projectList.connect(SEL_COMMAND, method(:onProjectSelect))
        @projectList.connect(SEL_DOUBLECLICKED, method(:openProject))
        
        
        #
        # SECOND WIZZARD FRAME
        #
        step_two_frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @projectCaption = FXLabel.new(step_two_frame, "Project: - unknown -", :opts => LAYOUT_FILL_X|JUSTIFY_LEFT)
        @projectCaption.setFont(FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        
        # SESSION SELECTION
        sessionSelectionFrame = FXGroupBox.new(step_two_frame, "Select Session", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        
        sessionSubSelection = FXVerticalFrame.new(sessionSelectionFrame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        newSessionFrame = FXHorizontalFrame.new(sessionSubSelection, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        FXLabel.new(newSessionFrame, "Session Name:" )
        @sessionTextField = FXTextField.new(newSessionFrame, 25,
                                            :target => @new_session_name, :selector => FXDataTarget::ID_VALUE,
                                            :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
        @newSessionButton = FXButton.new(newSessionFrame, "New" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        
        
        @new_session_name.connect(SEL_COMMAND, method(:createSession))
        
        @newSessionButton.connect(SEL_COMMAND, method(:createSession))
        
        sessionListOuterFrame = FXVerticalFrame.new(sessionSubSelection, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :padding => 0)
        @sessionList = FXList.new(sessionListOuterFrame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @sessionList.numVisible = 14
        
        @sessionList.connect(SEL_COMMAND, method(:onSessionSelect))
        
        @sessionList.connect(SEL_DOUBLECLICKED, method(:openSession))
        
        
        #updateSessionList(@project_dir)
        
        #
        # BUTTONS FRAME
        #
        buttons_frame = FXHorizontalFrame.new(base_frame,
                                              :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
        
        @finishButton = FXButton.new(buttons_frame, "Finish" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @finishButton.disable
        @finishButton.connect(SEL_COMMAND) do |sender, sel, item|
          #self.handle(self, FXSEL(SEL_COMMAND, ID_CANCEL), nil)
          self.handle(self, FXSEL(SEL_COMMAND, ID_ACCEPT), nil)
        end 
        
        @nextButton = FXButton.new(buttons_frame, "Next" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @nextButton.disable
        @nextButton.connect(SEL_COMMAND) do |sender, sel, item|
          if @switcher.current < @switcher.numChildren-1
            @switcher.current = @switcher.current+1
            @backButton.enable
            @nextButton.disable if @switcher.current == @switcher.numChildren-1 
          end
          setButtons(@switcher.current)
        end 
        
        @backButton = FXButton.new(buttons_frame, "Back" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        @backButton.disable
        @backButton.connect(SEL_COMMAND) do |sender, sel, item|
          if @switcher.current > 0
            @switcher.current = @switcher.current-1
            @backButton.disable if @switcher.current == 0
          end
          setButtons(@switcher.current)
        end 
        
        @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
        :target => self, :selector => FXDialogBox::ID_CANCEL,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)  
        
        
        updateProjectList(@workspace_dt.value)
        
        
        
        # apply setting
      end
      
      
    end
    
    
  end
end
