# @private 
module Watobo#:nodoc: all
   module Gui
      class WorkspaceDialog < FXDialogBox

         attr :workspace_dir

         def open_select_workspace_dir_dialog(sender, sel, ptr)
            workspace_dir = FXFileDialog.getOpenDirectory(self, "Select Workspace Directory", @workspace_dir.value)
            if workspace_dir != "" then
               if File.exist?(workspace_dir) then
                  @workspace_dir.value = workspace_dir
                  @workspace_dir.handle(self, FXSEL(SEL_UPDATE, 0), nil)
                  updateProjectList(@workspace_dir.value)
               end
            end
         end


         def initialize(parent, prefs)
            # Invoke base class initialize function first
            #  super(parent, "New Project", DECOR_TITLE|DECOR_BORDER)
            super(parent, "Define Workspace", DECOR_ALL)

            @workspace_dir = FXDataTarget.new('')

            if prefs[:workspace_dir] then
               if File.exist?(prefs[:workspace_dir]) then
                  @workspace_dir.value = prefs[:workspace_dir]
               end
            end

            base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            workspace_path_form = FXHorizontalFrame.new(base_frame,
            :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            FXLabel.new(workspace_path_form, "Workspace Directory:" )
            @workspaceText = FXTextField.new(workspace_path_form, 60,
            :target => @workspace_dir, :selector => FXDataTarget::ID_VALUE,
            :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN)

            browse_button=FXButton.new(workspace_path_form, "Change")
            browse_button.connect(SEL_COMMAND, method(:open_select_workspace_dir_dialog) )


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


            @cancelButton = FXButton.new(buttons_frame, "Cancel" ,
            :target => self, :selector => FXDialogBox::ID_CANCEL,
            :opts => BUTTON_NORMAL|LAYOUT_RIGHT)



         end
      end
   end
end
