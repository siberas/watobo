require 'watobo/gui/conversation_table'

# @private 
module Watobo#:nodoc: all
  module Gui
    class ConfirmScanDialog < FXDialogBox

      include Responder

      attr :scope
      def onAccept(sender, sel, event)

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

      def initialize(owner, chatlist, scan_settings={})
        super(owner, "Confirm Scan", DECOR_ALL, :width => 500, :height => 400)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        FXLabel.new(base_frame, "The following #{chatlist.length} chats will be scanned:")

        # @chatTable = ConversationTable.new(base_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        puts chatlist.length
        @chatTable = ConversationTable.new(base_frame)
        @chatTable.showConversation(chatlist)

        buttons_frame = FXHorizontalFrame.new(base_frame,
        :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)

        @finishButton = FXButton.new(buttons_frame, "Accept" ,  nil, nil, :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        @finishButton.enable
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
