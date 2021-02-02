module Watobo
  module Gui
    module SubFrames
      class EgressHandlerSelection < FXHorizontalFrame

        def egress_handler
          @egress.checked? ? @egress_handlers.getItem(@egress_handlers.currentItem) : ''
        end

        def initialize(parent, opts = {})
          prefs = {padding: 0}
          prefs.merge opts
          super(parent, prefs)
          @egress = FXCheckButton.new(self, "Egress", nil, 0, JUSTIFY_LEFT | JUSTIFY_CENTER_Y | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)


          @egress_handlers = FXComboBox.new(self, 5, nil, 0, COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP)
          #@filterCombo.width =200

          @egress_handlers.numVisible = 0
          @egress_handlers.numColumns = 23
          @egress_handlers.editable = false
          @egress_handlers.connect(SEL_COMMAND) { |sender, sel, name|
            Watobo::EgressHandlers.last = name
          }

          # @egress_handlers.appendItem('none', nil)
          @egress_add_btn = FXButton.new(self, "add", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
          @egress_add_btn.connect(SEL_COMMAND) { add_handler }
          #@egress_handlers.connect(SEL_COMMAND, method(:onRequestChanged))
          @egress_btn = FXButton.new(self, "reload", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
          @egress_btn.connect(SEL_COMMAND) {
            Watobo::EgressHandlers.reload
            update_egress
          }

          update_egress

          i = @egress_handlers.findItem(Watobo::EgressHandlers.last)
          #puts "Last Item Index: #{i} (#{Watobo::EgressHandlers.last})"
          @egress_handlers.setCurrentItem(i) if i >= 0


        end

        def add_handler
          @handler_path ||= Watobo.working_directory + '/'
          handler_filename = FXFileDialog.getOpenFilename(self, "Select handler file", @handler_path, "*.rb\n*")
          if handler_filename != "" then
            if File.exist?(handler_filename) then
              @handler_file = handler_filename
              @handler_path = File.dirname(handler_filename) + "/"
              Watobo::EgressHandlers.add(handler_filename)
              update_egress
            end
          end

        end

        def update_egress
          #binding.pry
          last_item = @egress_handlers.currentItem
          @egress_handlers.clearItems
          @egress.disable
          @egress_handlers.disable
          if Watobo::EgressHandlers.length > 0
            @egress.enable
            @egress_handlers.enable
            #@egress_btn.enable
            Watobo::EgressHandlers.list { |h|
              @egress_handlers.appendItem(h.to_s, nil)
            }
          end
          @egress_handlers.currentItem = last_item if last_item >= 0
        end


      end
    end
  end
end