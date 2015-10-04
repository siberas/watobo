# @private 
module Watobo#:nodoc: all
  module Gui
    class SaveChatDialog < FXDialogBox
      class Sender < Watobo::Session
        def initialize()
          @project = Watobo::Gui.project
          super(@project.object_id,  @project.getScanPreferences())

        end

        def send_request(new_request, opts = {} )
          prefs = {
            :run_login => false,
            :update_csrf_tokens => false
          }
          prefs.update opts

          id = 0
          if prefs[:run_login ] == true
            puts prefs.to_yaml
            puts "Scanner Settings:"
            puts Watobo::Conf::Scanner.to_h.to_yaml
            runLogin( prefs[:login_chats], prefs)
          end
          #if prefs[:update_session ] == true and
          unless prefs[:update_csrf_tokens] == true
            prefs[:csrf_requests] = []
            prefs[:csrf_patterns] = []
          end

          new_request.extend Watobo::Mixin::Parser::Web10
          new_request.extend Watobo::Mixin::Shaper::Web10
          begin
            test_req, test_resp = self.doRequest(new_request, prefs)
          rescue => bang
            puts bang
          end
          return test_req,test_resp
        end

      end
      include Responder

      def filename
        @filename_txt.text
      end

      def initialize(owner, chat, prefs={})
        raise ArgumentError, "Need Chat Object" unless chat.respond_to? :request
        super(owner, "Save Response", :opts => DECOR_ALL)
        @chat = chat
        @sender = Sender.new
        @response = chat.response

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @path = Watobo.workspace_path

        main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

        frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame,"Response:")
        @reload_btn = FXButton.new(frame, "Reload", nil, self, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_Y|LAYOUT_SIDE_RIGHT)

        @response_viewer = Watobo::Gui::ResponseViewer.new(main_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @response_viewer.setText(@response)
        @reload_btn.connect(SEL_COMMAND){
          s,a = @sender.send_request(@chat.request)
          @response = a
          @response.extend Watobo::Mixin::Parser::Web10
          @response.extend Watobo::Mixin::Shaper::Web10
          @response_viewer.setText(@response)
        }

        frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Save To:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @filename_txt = FXTextField.new(frame,  25, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
        @select_btn = FXButton.new(frame, "Select")
        @select_btn.connect(SEL_COMMAND){ select_target_file }
        if @chat.respond_to? :response
        @select_btn.enable
        @filename_txt.enable
        else
        @select_btn.disable
        @filename_txt.disable
        end

        buttons = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        accept = FXButton.new(buttons, "&Save", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        accept.enable
        # Cancel
        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
      end

      private

      def select_target_file()
        file = @chat.request.file
        file = "chat.txt" if file.strip.empty?
        dst_file = File.join(@path, file)
        filename = FXFileDialog.getSaveFilename(self, "Select Destination File", dst_file)
        if filename != "" then
        @filename_txt.text = filename
        end
      end

      def updateFields()
        # @sites_combo.handle(self, FXSEL(SEL_UPDATE, 1), nil)

      end

      def onAccept(sender, sel, event)
        begin
          f = @filename_txt.text
          if f != ''
            @path = File.dirname(f)

            if @response.has_body?
              File.open(f,"wb"){ |fh| fh.print @response.body }
            end
          end
          status = 1
        rescue => bang
          puts bang
          status = 0
        ensure
          getApp().stopModal(self, 1)
        self.hide()
        return status
        end

      end
    end

  end
end
