# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class PreScriptFrame < FXVerticalFrame

          include Watobo::Subscriber

          def script
            @text.rawRequest
          end

          def script=(data)
            @text.setText(data)
          end
          

          def egress_handler
            return nil unless @egress.checked?
            @egress_handlers.getItem(@egress_handlers.currentItem)
          end

          def egress_handler_enabled
            @egress.checked?
          end

          def egress_handler_enabled=(state)
            return false if state.nil?
            @egress.checkState = state
          end

          def initialize(owner, opts)
            frame_opts = {}
            frame_opts[:opts] = opts
            super(owner, frame_opts)

            gbframe = FXGroupBox.new(self, "Egress Handler", LAYOUT_SIDE_RIGHT | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            frame = FXHorizontalFrame.new(gbframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            @egress = FXCheckButton.new(frame, "enable", nil, 0,
                                        ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)

            @egress.checkState = false
            @egress.connect(SEL_COMMAND) { |sender, sel, name|
              notify(:text_changed)
            }

            @egress_handlers = FXComboBox.new(frame, 5, nil, 0, COMBOBOX_STATIC | FRAME_SUNKEN | FRAME_THICK | LAYOUT_SIDE_TOP)
            #@filterCombo.width =200

            @egress_handlers.numVisible = 0
            @egress_handlers.numColumns = 23
            @egress_handlers.editable = false
            @egress_handlers.connect(SEL_COMMAND) { |sender, sel, name|
              Watobo::EgressHandlers.last = name
            }

            eframe = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            # @egress_handlers.appendItem('none', nil)
            @egress_add_btn = FXButton.new(eframe, "add", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
            @egress_add_btn.connect(SEL_COMMAND) { add_handler }
            #@egress_handlers.connect(SEL_COMMAND, method(:onRequestChanged))
            @egress_btn = FXButton.new(eframe, "reload", nil, nil, 0, FRAME_RAISED | FRAME_THICK)
            @egress_btn.connect(SEL_COMMAND) {
              Watobo::EgressHandlers.reload
              update_egress
            }

            update_egress


            @text = Watobo::Gui::SimpleTextView.new(self, :opts => FRAME_THICK | FRAME_SUNKEN | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @text.editable = true
            @text.subscribe(:text_changed) do
              notify(:text_changed)
            end

          end

          private

          def update_egress
            @egress_handlers.clearItems
            @egress.disable
            @egress_handlers.disable
            if Watobo::EgressHandlers.length > 0
              @egress.enable
              @egress_handlers.enable
              #@egress_btn.enable
              Watobo::EgressHandlers.list {|h|
                @egress_handlers.appendItem(h.to_s, nil)
              }
            end
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
        end
      end
    end
  end
end


