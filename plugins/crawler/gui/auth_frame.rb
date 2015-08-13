# @private 
module Watobo#:nodoc: all
  module Plugin
    module Crawler
      class Gui
        class FormFieldsTable < FXTable
          def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
          end

          def clearEvents(event)
            @event_dispatcher_listener[event].clear
          end

          def update_fields
            self.getNumRows.times do |i|
              self.getItemData(i,0).value = self.getItemText(i,2)
            end
          end

          def clear_fields
            initTable
          end

          def initialize(owner, opts={})
            super(owner, opts)

            @event_dispatcher_listeners = Hash.new
            initTable()

            self.connect(SEL_COMMAND, method(:onTableClick))

            self.columnHeader.connect(SEL_COMMAND) do |sender, sel, index|
            # self.fitColumnsToContents(index)
            end
          end

          def add_field(field)
            lastRowIndex = self.getNumRows
            self.appendRows(1)
            self.setItemData(lastRowIndex, 0, field)
            self.setItemText(lastRowIndex, 0, field.name)
            self.getItem(lastRowIndex, 0).justify = FXTableItem::LEFT
            self.setItemText(lastRowIndex, 1, field.type)
            puts field.methods.sort
            self.getItem(lastRowIndex, 1).justify = FXTableItem::LEFT
            self.setItemText(lastRowIndex, 2, field.value)
            self.getItem(lastRowIndex, 2).justify = FXTableItem::LEFT

          end
          private

          def onTableClick(sender, sel, item)
            begin
              row = item.row
              self.selectRow(row, false)
              self.startInput(row,2)
            rescue => bang
              puts bang
            end
          end

          def notify(event, *args)
            if @event_dispatcher_listeners[event]
              @event_dispatcher_listeners[event].each do |m|
                m.call(*args) if m.respond_to? :call
              end
            end
          end

          def initTable
            self.clearItems()
            self.setTableSize(0, 3)

            self.setColumnText( 0, "Name" )
            self.setColumnText( 1, "Type" )
            self.setColumnText( 2, "Value" )

            self.rowHeader.width = 0
            self.setColumnWidth(0, 100)
            self.setColumnWidth(1, 100)
            self.setColumnWidth(2, 100)
          end
        end

        class AuthFrame < FXVerticalFrame
          attr_accessor :crawler
          def subscribe(event, &callback)
            (@event_dispatcher_listeners[event] ||= []) << callback
          end

          def clearEvents(event)
            @event_dispatcher_listener[event].clear
          end
          
          def set(settings)
            return false unless settings.has_key? :auth_type
            if settings[:auth_type] == :basic
              @auth_type_dt.value = 1
              @basic_auth_user_txt.text = settings.has_key?(:username) ? settings[:username] : ""
              pw = settings.has_key?(:password) ? settings[:password] : ""
              @basic_auth_passwd_txt.text = pw
              @basic_auth_retype_txt.text = pw
              
            end
             @switcher.current = @auth_type_dt.value
             update_form
             return true
          end

          def to_h
            a = case @auth_type_dt.value
            when 0
              {
                :auth_type => :none
              }
            when 1
              {
                :auth_type => :basic,
                :username => @basic_auth_user_txt.text,
                :password => @basic_auth_passwd_txt.text,
                :retype => @basic_auth_retype_txt.text
                #  :uri => URI.parse
              }
            when 2
              @form_fields_table.update_fields

              {
                :auth_type => :form,
                :form => @auth_form,
                :cookie_jar => @agent.respond_to?(:cookie_jar) ? @agent.cookie_jar : nil
              }
            end
            a

          end

         # def set(settings)
         #   @form_auth_url_txt.text = settings[:form_auth_url].to_s if settings.has_key? :form_auth_url
         #   update_form
         # end

          def update_form
            [ @form_auth_url_txt, @no_auth_rb, @basic_auth_rb, @form_auth_rb ].each do |e|
              e.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
          end

          def initialize(owner, opts={})
            super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_RAISED, :padding => 0)
            frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            #left_frm = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_Y|FRAME_NONE)
            @event_dispatcher_listeners = Hash.new
            @crawler = opts[:crawler] if opts.has_key? :crawler
            @start_url = ""

            auth_gb= FXGroupBox.new(frame, "Authentication", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            auth_frm = FXVerticalFrame.new(auth_gb, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE)
            @auth_form = nil
            @auth_type_dt = FXDataTarget.new(0)

            @no_auth_rb = FXRadioButton.new(auth_frm, "None", @auth_type_dt, FXDataTarget::ID_OPTION)

            @basic_auth_rb = FXRadioButton.new(auth_frm, "Basic", @auth_type_dt, FXDataTarget::ID_OPTION + 1)

            @form_auth_rb = FXRadioButton.new(auth_frm, "Form", @auth_type_dt, FXDataTarget::ID_OPTION + 2)

            # group_box = FXGroupBox.new(self, "Collection",LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            # frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_GROOVE)
            # @collectionList = FXList.new(frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            @switcher = FXSwitcher.new(auth_frm,LAYOUT_FILL_X|LAYOUT_FILL_Y)
            frame = FXHorizontalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE)
            FXLabel.new(frame, "No Authentication Selected", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            frame = FXHorizontalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE)
            FXLabel.new(frame, "Username:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @basic_auth_user_txt = FXTextField.new(frame, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)
            FXLabel.new(frame, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @basic_auth_passwd_txt = FXTextField.new(frame, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)
            FXLabel.new(frame, "Retype:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @basic_auth_retype_txt = FXTextField.new(frame, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

            form_auth_frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE)
            frame = FXHorizontalFrame.new(form_auth_frame, :opts => LAYOUT_FILL_X|FRAME_NONE)
            FXLabel.new(frame, "URL of LoginForm, leave empty to use Start URL:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @form_auth_url_txt = FXTextField.new(frame, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_X)
            @fetch_button = FXButton.new(frame, "load page", :opts => BUTTON_DEFAULT|BUTTON_NORMAL )

            form_frame = FXHorizontalFrame.new(form_auth_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_NONE)
            frame = FXHorizontalFrame.new(form_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @page_tree = Watobo::Gui::PageTree.new(frame)
            frame = FXHorizontalFrame.new(form_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK)
            @form_fields_table = FormFieldsTable.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            @auth_type_dt.connect(SEL_COMMAND) {
              @basic_auth_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @form_auth_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @no_auth_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @switcher.current = @auth_type_dt.value
            }
            
            @basic_auth_passwd_txt.connect(SEL_CHANGED){ password_check }
             @basic_auth_retype_txt.connect(SEL_CHANGED){ password_check }

            @fetch_button.connect(SEL_COMMAND){
              begin
                @form_fields_table.clear_fields
                @page_tree.clearItems

                page = nil
                url = nil
               
               if @form_auth_url_txt.text.empty?
                unless Watobo::Plugin::Crawler.start_url.nil?
                  uri = Watobo::Plugin::Crawler.start_url
                end
                else
                   url = @form_auth_url_txt.text unless @form_auth_url_txt.text.empty?
                  uri = URI.parse(url) 
                end

                notify(:log, "GET PAGE << #{uri.to_s}")
                @agent, page = @crawler.get_page(uri)
                notify(:log, "PAGE LOADED")
                @page_tree.page = page
              rescue => bang
                notify(:log, "could not get page #{uri.to_s}")
                puts "Could not get page for #{uri.to_s}"
                puts bang
                puts bang.backtrace if $DEBUG
              end
              true
            }
            @switcher.current = @auth_type_dt.value

            @page_tree.subscribe(:form_selected){|form|
              @auth_form = form
              @form_fields_table.clear_fields
              form.fields.each do |field|
                @form_fields_table.add_field field
              end
              form.buttons.each do |field|
                @form_fields_table.add_field field
              end
            }

          end

          private
          
          def password_check
              unless @basic_auth_passwd_txt.text == @basic_auth_retype_txt.text
              @basic_auth_retype_txt.backColor = FXColor::Red
              else
                @basic_auth_retype_txt.backColor = FXColor::Green
            end
          end

          def notify(event, *args)
            if @event_dispatcher_listeners[event]
              @event_dispatcher_listeners[event].each do |m|
                m.call(*args) if m.respond_to? :call
              end
            end
          end

          def enable_basic_auth

          end

          def disable_basic_auth

          end

          def enable_form_auth

          end

          def disable_form_auth

          end

        end
      end
    end
  end
end