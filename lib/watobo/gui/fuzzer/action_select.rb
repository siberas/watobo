module Watobo #:nodoc: all


  module Gui

    module Fuzzer

      class ActionSelect < FXVerticalFrame
        include Watobo

        def updateFields
          @b64_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @url_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @md5_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
          @ruby_proc_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)

        end

        def createAction()
          action = case @source_dt.value
                   when 0
                     action_proc = proc { |input| Base64.encode64(input) }
                     Action.new(action_proc, :action_type => 'Encode: Base64')
                   when 1
                     action_proc = proc { |input| CGI::escape(input) }
                     Action.new(action_proc, :action_type => 'Encode: URL')
                   when 2
                     action_proc = proc { |input| Digest::MD5.hexdigest(input) }
                     Action.new(action_proc, :action_type => 'Hash: MD5')
                   when 3
                     begin
                       #  puts "* Action: Proc"
                       # puts @textbox.to_s
                       code = @textbox.to_s
                       action_proc = eval(code)
                         # puts action_proc

                     rescue SyntaxError => bang
                       puts bang
                       puts code
                     rescue LocalJumpError => bang
                       puts bang
                       puts code
                     rescue SecurityError => bang
                       puts "desired functionality forbidden. it may harm your system!"
                       puts code
                     rescue => bang
                       puts bang
                       puts code

                     end
                     if action_proc
                       Action.new(action_proc, :action_type => "Ruby: Proc", :info => "#{@textbox.to_s}")
                     else
                       nil
                     end
                   end

          return action
        end


        def initialize(owner, interface, opts)
          super(owner, opts)

          @interface = interface

          group_box = FXGroupBox.new(self, "Select Action", LAYOUT_FILL_X | LAYOUT_FILL_Y, 0, 0, 0, 0)
          @source_dt = FXDataTarget.new(0)

          @source_dt.connect(SEL_COMMAND) do
            @b64_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @url_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @md5_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @ruby_proc_rb.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            if @source_dt.value != 3
              @textbox.enabled = false
              @textbox.backColor = FXColor::LightGrey
            else
              @textbox.enabled = true
              @textbox.backColor = FXColor::White
            end

          end

          begin
            frame = FXVerticalFrame.new(group_box, LAYOUT_FILL_X)
            @b64_rb = FXRadioButton.new(frame, "Encode Base64", @source_dt, FXDataTarget::ID_OPTION)

            frame = FXVerticalFrame.new(group_box, LAYOUT_FILL_X)
            @url_rb = FXRadioButton.new(frame, "Encode URL", @source_dt, FXDataTarget::ID_OPTION + 1)
            #      @textbox = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :width => 100, :height => 100)

            frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X)
            @md5_rb = FXRadioButton.new(frame, "Hash MD5", @source_dt, FXDataTarget::ID_OPTION + 2)

            frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y)
            @ruby_proc_rb = FXRadioButton.new(frame, "Ruby Proc", @source_dt, FXDataTarget::ID_OPTION + 3)
            text_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_THICK | FRAME_SUNKEN, :padding => 0)
            @textbox = FXText.new(text_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :width => 100, :height => 100)
            proc_skeleton = "proc { |input|\n# place your code betweenhere\n# e.g. 'input + \"TAIL\"\n\n\n# and here\n}"
            @textbox.setText(proc_skeleton)
            @textbox.enabled = false
            @textbox.backColor = FXColor::LightGrey


              # @textbox.editable = true
          rescue => bang
            puts "AAAAAA"
            puts bang
          end
          updateFields()

        end
      end
    end

  end
end
