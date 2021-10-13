# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Nuclei
      class Gui
        class RequestFrame < FXVerticalFrame

          include Subscriber

          def request
            @request_editor.parseRequest
          end

          def initialize(owner, opts)
            super(owner, opts)

            @source_dt = FXDataTarget.new(0)

            @source_dt.connect(SEL_COMMAND) do
              case @source_dt.value
              when 0
                @request_id_txt.disable
              when 1
                @request_id_txt.enable
              end

              @request_id_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)

            end

            # use switcher for tab specific help text
            @switcher = FXSwitcher.new(self, LAYOUT_FILL_X)
            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "Site/Path Selection")
            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "ChatID Selection")
            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "URL Selection")



            @request_tab = FXTabBook.new(self, nil, 0, :opts => LAYOUT_FILL_X, padding: 0)
            @request_tab.connect(SEL_COMMAND) do

                @switcher.setCurrent(@request_tab.current)

            end
            #
            # SITE / PATH TAB
            #
            FXTabItem.new(@request_tab, "Site/Path", nil)
            frame = FXVerticalFrame.new(@request_tab, :opts => LAYOUT_FILL_X | FRAME_RAISED)
            @sites_combo = FXComboBox.new(frame, 5, nil, 0,
                                          COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
            #@filterCombo.width =200

            @sites_combo.numVisible = 20
            @sites_combo.numColumns = 35
            @sites_combo.editable = false
            @sites_combo.connect(SEL_COMMAND, method(:onSiteSelect))


            FXLabel.new(frame, "Root Directory:")
            @dir_combo = FXComboBox.new(frame, 5, nil, 0,
                                        COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP | LAYOUT_FILL_X)
            @dir_combo.numVisible = 20
            @dir_combo.numColumns = 35
            @dir_combo.editable = false
            @dir_combo.connect(SEL_COMMAND, method(:onDirSelect))


            #
            # CHAT-ID TAB
            #p
            @chat_id_dt = FXDataTarget.new('')
            FXTabItem.new(@request_tab, "Chat-ID", nil)

            tab_frame = FXVerticalFrame.new(@request_tab, :opts => LAYOUT_FILL_X | FRAME_RAISED)
            FXLabel.new(tab_frame, "Enter Chat-ID or press 'select' to choose from list:")
            frame = FXHorizontalFrame.new(tab_frame, :opts => LAYOUT_FILL_X, :padding => 0)
            @chat_id_txt = FXTextField.new(frame, 1, :target => @chat_id_dt, :selector => FXDataTarget::ID_VALUE,
                                           :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_COLUMN)

            # @chat_id_txt.connect(SEL_COMMAND) { update_request }


            @select_button = FXButton.new(frame, "select", nil, nil, 0, :opts => FRAME_RAISED | FRAME_THICK)
            @select_button.connect(SEL_COMMAND) { select_chat }


            #
            # URL TAB
            #
            FXTabItem.new(@request_tab, "URL", nil)
            frame = FXVerticalFrame.new(@request_tab, :opts => LAYOUT_FILL_X | FRAME_RAISED)
            FXLabel.new(frame, "Enter URL:")


            @request_url_dt = FXDataTarget.new("")

            @request_url_txt = FXTextField.new(frame, 30,
                                               :target => @request_url_dt, :selector => FXDataTarget::ID_VALUE,
                                               :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_FILL_X)
            @request_url_txt.handle(self, FXSEL(SEL_UPDATE, 0), nil)


            ##############

            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)
            @generate_btn = FXButton.new(frame, "Create Request", nil, nil, 0, :opts => FRAME_RAISED | FRAME_THICK)
            @generate_btn.connect(SEL_COMMAND) { generate_request }

            FXLabel.new frame, "from settings above or paste request as text"
            sunken_frame = FXVerticalFrame.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
            @request_editor = Watobo::Gui::RequestEditor.new(sunken_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            @request_editor.subscribe(:text_changed) do
              notify(:sel_changed) unless @request_editor.parseRequest.empty?
            end

            updateView
          end

          # End-Of-INITIALIZE

          private


          def update_request

          end

          def generate_request
            ctab = @request_tab.current
            if ctab == 0
              request = get_request_from_site_select
              updateRequestEditor(request) unless request.nil?
            elsif ctab == 1
              chat_id = @chat_id_dt.value
              if chat_id.empty?
                FXMessageBox.information(self, MBOX_OK, "Chat-ID missing", "please enter a valid chat-id")
                return false
              end

              chat = Watobo::Chats.get_by_id chat_id
              if chat.nil?
                FXMessageBox.information(self, MBOX_OK, "Chat-ID wrong", "please enter a valid chat-id")
                return false
              end
              updateRequestEditor(chat.request)
            elsif ctab == 2
              url = @request_url_dt.value
              request = Watobo::Request.new url
              updateRequestEditor(request)
            end
          end

          def updateRequestEditor(request = nil)
            @request_editor.setText('')
            return false if request.nil?
            @request_editor.setText(request.join.gsub(/\r/, ""))
          end

          def select_chat
            begin
              dlg = Watobo::Gui::SelectChatDialog.new(self, "Select Login Chat")
              if dlg.execute != 0 then

                chats_selected = dlg.selection.value.split(",")

                chats_selected.each do |chatid|
                  chat = Watobo::Chats.get_by_id(chatid.strip)
                  if chat
                    @request_editor.setRequest chat.request
                  end
                end
              end
            rescue => bang
              puts "!!!ERROR: could not open SelectChatDialog."
              puts bang
            end
          end

          def onSiteSelect(sender, sel, item)
            ci = @sites_combo.currentItem
            @request_editor.setText('')

            @dir_combo.clearItems()
            @dir = ""

            if ci > 0 then
              @site = @sites_combo.getItemData(ci)
              if @site
                @dir_combo.appendItem("/", nil)

                chats = Watobo::Chats.select(@site, :method => "GET")
                updateRequestEditor(chats.first.request)

                Watobo::Chats.dirs(@site).each do |dir|
                  text = "/" + dir.slice(0..80)
                  text.gsub!(/\/+/, '/')
                  @dir_combo.appendItem(text, dir)
                end
                @dir_combo.setCurrentItem(0, true) if @dir_combo.numItems > 0
              end
              @dir_combo.enable


            else
              @site = nil
              @request_editor.setText('')
              @dir_combo.disable
            end
          end

          def onDirSelect(sender, sel, item)
            ci = @dir_combo.currentItem

            if ci > 0 then
              @dir = @dir_combo.getItemData(ci)
            else
              @dir = ""
            end
            chats = Watobo::Chats.select(@site, :method => "GET", :dir => @dir)

            if chats.empty?
              chats = Watobo::Chats.select(@site, :dir => @dir)
            end

            if !chats.empty?
              updateRequestEditor(chats.first.request)
            else
              updateRequestEditor([''])
            end

          end

          def get_request_from_site_select
            ci = @dir_combo.currentItem

            if ci > 0 then
              @dir = @dir_combo.getItemData(ci)
            else
              @dir = ""
            end
            chats = Watobo::Chats.select(@site, :method => "GET", :dir => @dir)
            return nil if chats.empty?
            chats.first.request
          end


          def updateView()
            #@project = project
            @sites_combo.clearItems()
            @dir_combo.clearItems()
            @dir_combo.disable


            @sites_combo.appendItem("no site selected", nil)
            Watobo::Chats.sites(:in_scope => Watobo::Scope.exist?).each do |site|
              #puts "Site: #{site}"
              next if site.nil?
              @sites_combo.appendItem(site.slice(0..35), site)
            end
            @sites_combo.setCurrentItem(0) if @sites_combo.numItems > 0
            ci = @sites_combo.currentItem
            site = (ci >= 0) ? @sites_combo.getItemData(ci) : nil
            @sites_combo.numVisible = @sites_combo.numItems
            @sites_combo.numColumns = 35

            if site
              @dir_combo.enable
              Watobo::Chats.dirs(@site) do |dir|
                @dir_combo.appendItem(dir.slice(0..35), dir)
              end
              @dir_combo.setCurrentItem(0, true) if @dir_combo.numItems > 0

            end
          end


        end
      end
    end
  end
end
