# @private 
module Watobo#:nodoc: all
  module Gui
    class EditScopeDialog < FXDialogBox

      include Responder

      attr :scope
      def onAccept(sender, sel, event)

        Watobo::Scope.set @defineScopeFrame.getScope()

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

      def initialize(owner, prefs)
        #super(owner, "Edit Target Scope", DECOR_TITLE|DECOR_BORDER, :width => 300, :height => 425)
        super(owner, "Edit Target Scope", DECOR_ALL, :width => 350, :height => 425)
        
        @scope = Hash.new

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        #  puts "create scopeframe with scope:"
        # @project.scope
        @defineScopeFrame = DefineScopeFrame.new(base_frame, prefs)

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
