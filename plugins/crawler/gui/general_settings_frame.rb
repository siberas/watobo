# @private 
module Watobo#:nodoc: all
  module Plugin
    module Crawler
      class Gui
        class GeneralSettingsFrame < FXVerticalFrame
          def to_h
            {
              :max_depth => @max_depth_txt.text.to_i,
              :max_threads => @max_threads_txt.text.to_i,
              :max_repeat => @max_repeat_txt.text.to_i,
              :delay => @delay_txt.text.to_i,
              # TODO: :user_agent => @user_agent_txt.text,
              :submit_forms => @submit_forms_cb.checked?,
              :excluded_fields => @excluded_field_patterns.to_a,
              :head_request_pattern => @rewrite_method_cb.checked? ? @head_request_pattern_txt.text : nil 
            }
          end

          def set(settings)
            @submit_forms_cb.checkState = settings[:submit_forms] if settings.has_key? :submit_forms
            @max_depth_txt.text = settings[:max_depth].to_s if settings.has_key? :max_depth
            @max_threads_txt.text = settings[:max_threads].to_s if settings.has_key? :max_threads
            @max_repeat_txt.text = settings[:max_repeat].to_s if settings.has_key? :max_repeat
            @head_request_pattern_txt.text = settings[:head_request_pattern].to_s if settings.has_key? :head_request_pattern
            @delay_txt.text = settings[:delay].to_s if settings.has_key? :delay
            @excluded_field_patterns.set settings[:excluded_fields] if settings.has_key? :excluded_fields
              
            update_form
          end

          def update_form
            [ @submit_forms_cb, @max_depth_txt, @max_threads_txt, @max_repeat_txt, @delay_txt, @head_request_pattern_txt, @excluded_field_patterns ].each do |e|
              e.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            end
          end

          def initialize(owner)
            super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            iframe = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|FRAME_THICK)

            outer_matrix = FXMatrix.new(iframe, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
            gbframe = FXGroupBox.new(outer_matrix, "Performance", FRAME_GROOVE|LAYOUT_FILL_Y, 0, 0, 0, 0)

            matrix = FXMatrix.new(gbframe, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            FXLabel.new(matrix, "Max. Depth:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @max_depth_txt = FXTextField.new(matrix, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            FXLabel.new(matrix, "Max. Threads:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @max_threads_txt = FXTextField.new(matrix, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            FXLabel.new(matrix, "Max. Repeat:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @max_repeat_txt = FXTextField.new(matrix, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            FXLabel.new(matrix, "Delay (ms):", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @delay_txt = FXTextField.new(matrix, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)



            gbframe = FXGroupBox.new(outer_matrix, "Form Handling", FRAME_GROOVE|LAYOUT_FILL_Y, 0, 0, 0, 0)
            iframe = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @submit_forms_cb = FXCheckButton.new(iframe, "Submit Forms", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @submit_forms_cb.checkState = true

            @fill_forms_cb = FXCheckButton.new(iframe, "Fill Forms", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @fill_forms_cb.checkState = false
            @fill_forms_cb.disable
            
            FXLabel.new(iframe, "Don't send forms if they contain following field names (regex):")
            @excluded_field_patterns = Watobo::Gui::ListBox.new(iframe)

            #f = FXVerticalFrame.new(outer_matrix, :opts =>LAYOUT_FILL_X|LAYOUT_FILL_Y)
            gbframe = FXGroupBox.new(outer_matrix, "Rewrite", FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            iframe = FXVerticalFrame.new(gbframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_WIDTH, :width => 250)
            fxtext = FXText.new(iframe, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_WORDWRAP)
            fxtext.backColor = fxtext.parent.backColor
            fxtext.disable
            text = "To speed up the crawl process and to save bandwidth it is recommended to use HEAD requests for specific document extensions."
            text << "The response to a HEAD request only includes the http headers but no body. The extensions pattern is defined as an regular expression (case insesitive),"
            text << "e.g. '(pdf|swf|doc|flv|jpg|png|gif)' - without quotes."

            fxtext.setText(text)
            
            @rewrite_method_cb = FXCheckButton.new(iframe, "Use HEAD method for:", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @rewrite_method_cb.checkState = true
            f = FXHorizontalFrame.new(iframe, :opts => LAYOUT_FILL_X)
            FXLabel.new(f, "Ext. Pattern:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @head_request_pattern_txt = FXTextField.new(f, 10, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
            @head_request_pattern_txt.text = '(pdf|swf|doc|flv|jpg|png|gif|zip|tar|gz|bz2|tgz)'

          end

        end
      end
    end
  end
end