# @private
module Watobo#:nodoc: all
  module Gui
    class ExportDialog < FXDialogBox
      def check_settings

      end

      def select_target_file()
        fname = "watobo_" + Time.now.to_i.to_s + ".xml"
        dst_file = File.join(@export_path, fname)
        filename = FXFileDialog.getSaveFilename(self, "Select Export File", dst_file)
        if filename != "" then

        @filename_txt.text = filename
        
        return true
        end
        return false
      end
      
      def onFinished
         getApp().stopModal(self, 1)
         self.hide()
         return 1
      end

      def initialize(owner)
        @export_path = Watobo.workspace_path
        super(owner, "Export Dialog", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 350, :height => 250)

        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

      #  frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
         gbox = FXGroupBox.new(main, "Items", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 80)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @export_chats = FXCheckButton.new(gbframe, "Chats", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @export_chats.checkState = true
        
        @export_findings = FXCheckButton.new(gbframe, "Findings", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @export_findings.checkState = true
        
        
        #  frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
         gbox = FXGroupBox.new(main, "Filter", LAYOUT_SIDE_LEFT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 80)
        gbframe = FXVerticalFrame.new(gbox, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @scope_only = FXCheckButton.new(gbframe, "Scope Only", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @scope_only.checkState = true
        
        @ignore_fps = FXCheckButton.new(gbframe, "Ignore False-Positives", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
        @ignore_fps.checkState = true
        

        frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Save To:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @filename_txt = FXTextField.new(frame,  25, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
        @select_btn = FXButton.new(frame, "Select")

        @select_btn.connect(SEL_COMMAND){ select_target_file }

        buttons_frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)

        @export_btn = FXButton.new(buttons_frame, "export" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @export_btn.enable
       @export_btn.connect(SEL_COMMAND){  onExport }
       
        @finished_btn = FXButton.new(buttons_frame, "finished" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finished_btn.enable
       @finished_btn.connect(SEL_COMMAND){  onFinished }

      end
      
      private
      
      def onExport
        #return false unless check_export_target
        prefs = []
        prefs << :export_findings if @export_findings.checked?
        prefs << :export_chats if @export_chats.checked?
        prefs << :scope_only if  @scope_only.checked?
        prefs << :ignore_fps if  @ignore_fps.checked?
        
        puts "Export-Prefs: #{prefs.join(", ")}"
        file = @filename_txt.text
        unless file.strip.empty?
          begin
        File.open(file, "w"){|fh|
        xml = Watobo::Utils.exportXML(*prefs)
        fh.puts xml.to_xml
        }
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        else
          #TODO
        end
      end
    end
  end
end

if __FILE__ == $0
# TODO Generated stub
end
