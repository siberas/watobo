# @private 
module Watobo#:nodoc: all
   module Gui
      class SelectChatDialog < FXDialogBox
         include Watobo::Gui::Utils
         attr :selection
         def chatClicked(item)
            begin
               @request_viewer.setText('')
               @response_viewer.setText('')
               #row = sender.getCurrentRow
               row = item.row
               if row >= 0 then
                  @chatTable.selectRow(row)
                  chatid = @chatTable.getRowText(row).to_i
                  # @logText.appendText("selected ID: (#{chatid})\n")
                  Watobo::Chats.each do |chat|
                     if chat.id == chatid then
                        @sel_chat = chatid

                        showChat(chat)
                        break
                     end
                  end
               end
            rescue => bang
               puts "!!!ERROR: onTableClick"
               puts bang
               puts "!!!"

            end
            0
         end

         def onTableClick(sender, sel, item)
            chatClicked(item)
         end

         def onTableDoubleClick(sender, sel, item)
            chatClicked(item)
            addSelection()
         end

         def showChat(chat)
            @request_viewer.setText(cleanupHTTP(chat.request))

            @response_viewer.setText(cleanupHTTP(chat.response))
         end

         def selectChat(sender, sel, item)
            addSelection()
         end

         def updateTable()
           chats = nil
           if @show_scope_only.checked?
             chats = Watobo::Chats.in_scope
           else
             chats = Watobo::Chats.to_a
           end
           @chatTable.showConversation( chats )

         end

         def addSelection()
            if @sel_chat then
               if @selection.value == '' then
                  @selection.value = @sel_chat.to_s
               else
                  @selection.value = @selection.value + "," + @sel_chat.to_s
               end
               @selection_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
         end

         def initialize(owner, title)
            #  @chat_selection = []
           
            @selection = FXDataTarget.new('')

            @sel_chat = nil
            super(owner, title, DECOR_ALL, :width=>600, :height=>600)
            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            splitter = FXSplitter.new(main_frame, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SPLITTER_VERTICAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
            top_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE, :height => 300, :padding => 0)

            preview_frame = FXVerticalFrame.new(splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :height => 300, :padding => 0)

           
               quick_filter_gb = FXGroupBox.new(top_frame, "Quick Filter", FRAME_GROOVE|LAYOUT_FILL_X)
               quick_filter_frame = FXHorizontalFrame.new(quick_filter_gb, :opts => FRAME_NONE|LAYOUT_FILL_X, :padding => 0)
               @show_scope_only = FXCheckButton.new(quick_filter_frame, "scope only", nil, 0, ICON_BEFORE_TEXT|LAYOUT_SIDE_LEFT)
               @show_scope_only.setCheck(false)
               @show_scope_only.connect(SEL_COMMAND) { updateTable }
            table_frame = FXVerticalFrame.new(top_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

            @chatTable = ConversationTable.new(table_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @chatTable.connect(SEL_CLICKED, method(:onTableClick))
            @chatTable.connect(SEL_DOUBLECLICKED, method(:onTableDoubleClick))


            selection_frame = FXHorizontalFrame.new(table_frame, :opts => LAYOUT_FILL_X)
            button = FXButton.new(selection_frame, "Select Chat >", nil, nil, 0, FRAME_RAISED|FRAME_THICK|LAYOUT_LEFT)
            button.connect(SEL_COMMAND, method(:selectChat))

            @selection_text = FXTextField.new(selection_frame, 20, @selection, FXDataTarget::ID_VALUE, FRAME_SUNKEN|FRAME_THICK|LAYOUT_FILL_X)
            #FXLabel.new(chat_filter_frame, "Filter")

            updateTable()

            tabBook = FXTabBook.new(preview_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT, :padding => 0)

            req_tab = FXTabItem.new(tabBook, "Request", nil)
            #@request_viewer = Watobo::Gui::ChatViewer.new(tabBook, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
            text_frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK)
            @request_viewer = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @request_viewer.editable = false

            resp_tab = FXTabItem.new(tabBook, "Response", nil)
            text_frame = FXVerticalFrame.new(tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK)
            @response_viewer = FXText.new(text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @response_viewer.editable = false

            # @response_viewer = Watobo::Gui::ChatViewer.new(tabBook, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

            button_frame = FXHorizontalFrame.new(main_frame, :opts => LAYOUT_FILL_X)
            FXButton.new(button_frame, "OK" ,
            :target => self, :selector => FXDialogBox::ID_ACCEPT,
            :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
            FXButton.new(button_frame, "Cancel" ,
            :target => self, :selector => FXDialogBox::ID_CANCEL,
            :opts => BUTTON_NORMAL|LAYOUT_RIGHT)

         end
      end
      #--
   end
end
