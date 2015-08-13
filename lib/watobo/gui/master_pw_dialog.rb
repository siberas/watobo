# @private 
module Watobo#:nodoc: all
  module Gui
    class MasterPWDialog < FXDialogBox

      include Responder

      attr :master_password
      def masterPassword
        @master_password
      end

      def initialize(owner, title="Set Master Password", new_opts = {})
        @opts = {
          :info => "Please provide a master password to encrypt your login credentials.\n\nIf you click 'cancel' your passwords will not be saved.",
          :retype => true
        }
        @opts.update new_opts
        super(owner, title, :opts => DECOR_TITLE|DECOR_BORDER|DECOR_CLOSE, :width => 300, :height => 350)

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        @master_password = nil
        @pw_first_dt = FXDataTarget.new('')
        @pw_second_dt = FXDataTarget.new('')
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

        #info_frame = FXButton.new(main, info_text, :opts => LAYOUT_FILL_X|FRAME_NONE)
        textbox = FXText.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        textbox.backColor = textbox.parent.backColor
        textbox.editable = false
        textbox.enabled = false
        textbox.textStyle |= TEXT_WORDWRAP

        textbox.setText @opts[:info]
        top_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X)

        FXLabel.new(top_frame, "Password:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
        @pw_first_txt = FXTextField.new(top_frame, 30,
        :target => @pw_first_dt, :selector => FXDataTarget::ID_VALUE,
        :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

        if @opts[:retype]

          FXLabel.new(top_frame, "Repeat:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
          @pw_second_txt = FXTextField.new(top_frame, 30,
          :target => @pw_second_dt, :selector => FXDataTarget::ID_VALUE,
          :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|TEXTFIELD_PASSWD)

          @pw_second_txt.connect(SEL_KEYRELEASE) {
            @acceptBtn.disable
            if @pw_first_txt.text == @pw_second_txt.text
              @acceptBtn.enable
              @acceptBtn.setFocus
              @acceptBtn.setDefault
            end
            false
          }
       else
        
=begin
@pw_first_txt.connect(SEL_KEYRELEASE) {
            @acceptBtn.disable
          
              @acceptBtn.enable
              @acceptBtn.setFocus
              @acceptBtn.setDefault
          
            false
          }
=end
        end

        buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
        :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)

        # Accept
        @acceptBtn = FXButton.new(buttons, "&Accept", nil, self, ID_ACCEPT,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        @acceptBtn.disable
        
        unless @opts[:retype]
          @acceptBtn.enable
                               @acceptBtn.setFocus
                               @acceptBtn.setDefault
        end

        FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
        FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        #  @hostname.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @domain.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @user.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        #  @email.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        #@pw_first_txt.enable
        @pw_first_txt.setFocus
        @pw_first_txt.setDefault
      end

      private

      def onAccept(sender, sel, event)
        @master_password = nil
        if @opts[:retype] == false or @pw_first_txt.text == @pw_second_txt.text then
          @master_password = @pw_first_txt.text
          # puts "* new MasterPassword #{@master_password}"
          getApp().stopModal(self, 1)
          self.hide()
          return 1
        else
          FXMessageBox.information(self, MBOX_OK, "Wrong Passwords", "The passwords you've entered don't match!")
        end

      end
    end

  end
end

if __FILE__ == $0
  # TODO Generated stub
end