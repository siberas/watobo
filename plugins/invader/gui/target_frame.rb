# @private
module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui
        class TargetFrame < FXVerticalFrame
          include Watobo::Gui
          include Watobo::Gui::Icons

          extend Watobo::Subscriber

          attr :editor

          def set_request(request)
            @editor.setRequest(request)
          end

          def get_request
            @editor.parseRequest
          end

          def get_snipers

          end

          # @returns mode [Const]
          # MODE_SNIPER 0x01
          # MODE_PARAM 0x00
          def mode
            @tabBook.current
          end

          def initialize(owner, opts)
            @chat = nil

            super(owner, opts)
            splitter = FXSplitter.new(self, LAYOUT_FILL_X | LAYOUT_FILL_Y | SPLITTER_HORIZONTAL | SPLITTER_REVERSED | SPLITTER_TRACKING)

            @editor = RequestEditor.new(splitter, :opts => FRAME_THICK | FRAME_SUNKEN | LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)

            @tabBook = FXTabBook.new(splitter, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)

            FXTabItem.new(@tabBook, "Parameters", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            frame = FXVerticalFrame.new(rframe, :opts => FRAME_SUNKEN | LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @all_chk = FXCheckButton.new(frame, "All", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @all_chk.checkState = false

            @headers_chk = FXCheckButton.new(frame, "Headers", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @headers_chk.checkState = false
            @cookies_chk = FXCheckButton.new(frame, "Cookies", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @cookies_chk.checkState = false

            @body_chk = FXCheckButton.new(frame, "WWW-Form", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @body_chk.checkState = false

            @body_chk = FXCheckButton.new(frame, "JSON", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @body_chk.checkState = false

            @body_chk = FXCheckButton.new(frame, "XML", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @body_chk.checkState = false

            @body_chk = FXCheckButton.new(frame, "Body", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @body_chk.checkState = false

            FXTabItem.new(@tabBook, "Sniper", nil)
            rframe = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            frame = FXHorizontalFrame.new(rframe, :opts => LAYOUT_FILL_X|FRAME_SUNKEN, :padding => 0)
            @ct_dt = FXDataTarget.new('%%')
            FXLabel.new(frame, "MARK:")
            @ct_field = FXTextField.new(frame, 4, :target => @ct_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
            @ct_field.disable
            frame = FXVerticalFrame.new(rframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)

            @add_ct_btn = FXButton.new(frame, "Add" , :opts => BUTTON_NORMAL|LAYOUT_FILL_X)
            @rem_ct_btn = FXButton.new(frame, "Clear" , :opts => BUTTON_NORMAL|LAYOUT_FILL_X)



          end


        end
      end
    end
  end
end
