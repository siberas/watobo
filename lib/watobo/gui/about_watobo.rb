# @private 
module Watobo#:nodoc: all
  
  
  module Gui
        
    class AboutWatobo < FXDialogBox
      def initialize(owner)
        super(owner, "About WATOBO", :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE|DECOR_RESIZE,:width=>600, :height=>600)
        self.icon = Watobo::Gui::Icons::ICON_WATOBO
        @font = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD)
        
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE, :padding => 0)
        main.backColor = FXColor::White
        #main.verticalScrollBar.setLine(@font.fontHeight)
        header = FXHorizontalFrame.new(main, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 590, :height => 100, :padding => 0)
        version = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X, :padding => 0)
        version.backColor = FXColor::White
        
        version_label  = FXLabel.new(version, "Version: #{Watobo.version}", nil, :opts => JUSTIFY_CENTER_X|LAYOUT_FILL_X)
        version_label.setFont(FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))
        version_label.backColor = FXColor::White
        version_label.justify = JUSTIFY_CENTER_X
        
        #lic_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        lic_frame = FXScrollWindow.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        
        bottom = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        
        @imageview = FXImageView.new(header,
                                     :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|HSCROLLER_NEVER|VSCROLLER_NEVER)
        
        @imageview.image = Watobo::Gui::Icons::WATOBO_LOGO
        
        btn = FXButton.new(lic_frame, Watobo::LICENSE,
                           :opts => LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 575, :height => 400)
        btn.font = @font
        btn.backColor = FXColor::White
        btn.justify = JUSTIFY_LEFT
        
        FXButton.new(bottom, "OK" ,
        :target => self, :selector => FXDialogBox::ID_ACCEPT,
        :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
        
      end 
    end
  end
end
