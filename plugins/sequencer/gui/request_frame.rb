# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class RequestFrame < FXVerticalFrame

          include Watobo::Subscriber

          def request
             @request_editor.rawRequest
          end

          def request=(request)
            @request_editor.setText(request)
          end

          def initialize(owner, opts)
            frame_opts = {}
            frame_opts[:opts] = opts
            super(owner, frame_opts)

            top_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)
            @select_btn = FXButton.new(top_frame, "Select", :opts => BUTTON_NORMAL)
            @select_btn.connect(SEL_COMMAND) { startSelectChatDialog }


            @request_editor = Watobo::Gui::RequestEditor.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)

            @request_editor.subscribe(:text_changed) do
              #puts "Text in editor changed"
              notify(:text_changed)
            end

          end


          def startSelectChatDialog
            begin
              dlg = Watobo::Gui::SelectChatDialog.new(self, "Select Chat")
              if dlg.execute != 0 then

                chats_selected = dlg.selection.value.split(",")

                chats_selected.each do |chatid|
                  chat = Watobo::Chats.get_by_id(chatid.strip)
                  if chat
                    @request_editor.setRequest(chat.request)
                    notify(:text_changed)
                  end
                end
              end
            rescue => bang
              puts "!!!ERROR: could not open SelectChatDialog."
              puts bang
            end
          end
        end
      end
    end
  end
end
