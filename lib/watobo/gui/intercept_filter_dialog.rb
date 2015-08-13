# @private 
module Watobo#:nodoc: all
  module Gui
    class InterceptFilterDialog < FXDialogBox

      include Responder
      def getRequestFilter()
        @request_filter
      end

      def getResponseFilter()
        @response_filter
      end

      def initialize(owner, settings = {} )
        super(owner, "Rewrite Settings", DECOR_ALL, :width => 300, :height => 425)

        @request_filter = { }

        @response_filter = { }

        @request_filter.update settings[:request_filter_settings]
        @response_filter.update settings[:response_filter_settings]

        FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)

        base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        @tabbook = FXTabBook.new(base_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
        buttons_frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X)
        @req_opt_tab = FXTabItem.new(@tabbook, "Request Options", nil)
        frame = FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_window = FXScrollWindow.new(frame, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @req_opt_frame = FXVerticalFrame.new(scroll_window, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        @resp_opt_tab = FXTabItem.new(@tabbook, "Response Options", nil)
        frame= FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        scroll_window = FXScrollWindow.new(frame, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @resp_opt_frame = FXVerticalFrame.new(scroll_window, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

        initRequestFilterFrame()
        updateRequestFilterFrame()

        initResponseFilterFrame()
        updateResponseFilterFrame()

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

      private

      def onAccept(sender, sel, event)
        #TODO: Check if regex is valid
        @request_filter[:method_filter] = @method_filter_dt.value
        @request_filter[:negate_method_filter] = @neg_method_filter_cb.checked?
        @request_filter[:negate_url_filter] = @neg_url_filter_cb.checked?
        @request_filter[:url_filter] = @url_filter_dt.value
        @request_filter[:file_type_filter] = @ftype_filter_dt.value
        @request_filter[:negate_file_type_filter] = @neg_ftype_filter_cb.checked?

        @request_filter[:parms_filter] = @parms_filter_dt.value
        @request_filter[:negate_parms_filter] = @neg_parms_filter_cb.checked?

        @response_filter[:content_type_filter] = @content_type_filter_dt.value
        @response_filter[:negate_content_type_filter] = @neg_ctype_filter_cb.checked?

        @response_filter[:response_code_filter] =  @rcode_filter_dt.value
        @response_filter[:negate_response_code_filter] = @neg_rcode_filter_cb.checked?

        getApp().stopModal(self, 1)
        self.hide()
        return 1
      end

      def updateRequestFilterFrame()
        @parms_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @url_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @ftype_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @method_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def updateResponseFilterFrame()
        @content_type_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
        @rcode_filter.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      # @neg_rcode_filter_cb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      # @neg_ctype_filter_cb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end

      def initResponseFilterFrame()

        gbframe = FXGroupBox.new(@resp_opt_frame, "Content Type", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP Content-Type. E.g., '(text|script)'"
        fxtext.setText(text)
        @content_type_filter_dt = FXDataTarget.new('')
        @content_type_filter_dt.value = @response_filter[:content_type_filter]
        @content_type_filter = FXTextField.new(frame, 20, :target => @content_type_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_ctype_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_ctype_filter_cb.checkState = @response_filter[:negate_content_type_filter]

        gbframe = FXGroupBox.new(@resp_opt_frame, "Response Code", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP Content-Type. E.g., '200'"
        fxtext.setText(text)
        @rcode_filter_dt = FXDataTarget.new('')
        @rcode_filter_dt.value = @response_filter[:response_code_filter]

        @rcode_filter = FXTextField.new(frame, 20, :target => @rcode_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_rcode_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_rcode_filter_cb.checkState = @response_filter[:negate_response_code_filter]

      end

      def initRequestFilterFrame()
        gbframe = FXGroupBox.new(@req_opt_frame, "URL Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular Expression Filter For URL. E.g., '.*www.mysite.com.*login.php'"
        fxtext.setText(text)

        @url_filter_dt = FXDataTarget.new('')
        @url_filter_dt.value = @request_filter[:url_filter]
        @url_filter = FXTextField.new(frame, 20, :target => @url_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_url_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_url_filter_cb.checkState = false
        @neg_url_filter_cb.checkState = @request_filter[:negate_url_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "Method Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for HTTP method. E.g., '(get|PoSt)'"
        fxtext.setText(text)
        @method_filter_dt = FXDataTarget.new('')
        @method_filter_dt.value = @request_filter[:method_filter]
        @method_filter = FXTextField.new(frame, 20, :target => @method_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_method_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_method_filter_cb.checkState = false
        @neg_method_filter_cb.checkState = @request_filter[:negate_method_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "Parm Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular Expression Filter For Parameter Names. E.g., for intercepting requests containing parameters beginning with 'act' use the regex pattern '^act.*' (without single quotes)"
        fxtext.setText(text)
        @parms_filter_dt = FXDataTarget.new('')
        @parms_filter_dt.value = @request_filter[:parms_filter]
        @parms_filter = FXTextField.new(frame, 20, :target => @parms_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_parms_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_parm_filter_cb.checkState = false
        @neg_parms_filter_cb.checkState = @request_filter[:negate_parms_filter]

        gbframe = FXGroupBox.new(@req_opt_frame, "File Type Filter", LAYOUT_SIDE_RIGHT|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X, :padding => 0)
        fxtext = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
        fxtext.backColor = fxtext.parent.backColor
        fxtext.disable
        text = "Regular expression for file types by its extension. E.g., for intercepting requests where file type is PHP use '^php$' (without single quotes)"
        fxtext.setText(text)
        @ftype_filter_dt = FXDataTarget.new('')
        @ftype_filter_dt.value = @request_filter[:file_type_filter]
        @ftype_filter = FXTextField.new(frame, 20, :target => @ftype_filter_dt, :selector => FXDataTarget::ID_VALUE, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT|LAYOUT_FILL_X)
        @neg_ftype_filter_cb = FXCheckButton.new(frame, "Negate Filter", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
        #@neg_parm_filter_cb.checkState = false
        @neg_ftype_filter_cb.checkState = @request_filter[:negate_file_type_filter]
      end
    end
  end
end