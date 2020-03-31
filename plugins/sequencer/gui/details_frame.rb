# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class DetailsFrame < FXVerticalFrame

          include Watobo::Subscriber

          def element=(e)
            @element_label.text = "Element: #{e.name}"
            @element = e

            @request_frame.request = @element.request
            @post_script_frame.script = @element.post_script
            @apply_btn.enable
          end

          def initialize(owner, opts)
            frame_opts = {}
            frame_opts[:opts] = opts
            super(owner, frame_opts)

            @element = nil
            #@element_btn = FXButton.new(self, element.name)

            top_frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X, :padding => 0)
            @element_label = FXLabel.new(top_frame, "Element: N/A", nil, LAYOUT_TOP | JUSTIFY_RIGHT)
            @apply_btn = FXButton.new(top_frame, "Apply", :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
            @apply_btn.connect(SEL_COMMAND) { apply_changes }
            @apply_btn.disable

            base_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)

            @tabbook = FXTabBook.new(base_frame, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            buttons_frame = FXHorizontalFrame.new(base_frame, :opts => LAYOUT_FILL_X)
            @req_opt_tab = FXTabItem.new(@tabbook, "Request", nil)
            #frame = FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @request_frame = RequestFrame.new( @tabbook, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)
            @request_frame.subscribe(:text_changed) do
              puts "Text in editor changed"
              element_changed
            end
            #@req_opt_tab.disable


            @prescript_tab = FXTabItem.new(@tabbook, "Pre-Script", nil)
            frame = FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            @postscript_tab = FXTabItem.new(@tabbook, "Post-Script", nil)
            @post_script_frame = PostScriptFrame.new(@tabbook, FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            @vars_tab = FXTabItem.new(@tabbook, "Vars", nil)
            frame = FXVerticalFrame.new(@tabbook, :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_FILL_Y)


          end

          private

          def apply_changes
            @apply_btn.textColor = 'black'
            @element.request = @request_frame.request
            @element.post_script = @post_script_frame.script
            notify(:element_changed)

          end

          def element_changed
            @apply_btn.textColor = 'red'
            @apply_btn.enable
          end

        end
      end
    end
  end
end

