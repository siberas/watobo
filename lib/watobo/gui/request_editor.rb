# @private
require 'watobo/gui/simple_text_view'
module Watobo #:nodoc: all
  module Gui


    class RequestEditor < SimpleTextView

      #alias_method :setRequest, :setText
      def setRequest(request)
        @request = request.copy
        rc = request.copy
        if rc.has_body?
          if rc.is_xml?
            doc = Nokogiri.XML(rc.body)
            rc.set_body doc.to_xml
          elsif rc.is_json?
            begin
            jb = JSON.parse(rc.body)
            rc.set_body JSON.pretty_generate jb
            rescue => bang
              puts bang if $DEBUG
              rc = request.copy
            end
          end
        end
        setText(rc)
      end

      def initialize(owner, opts)
        super(owner, opts)
        @keystate = true
        @request = nil

        @textbox.textStyle -= TEXT_WORDWRAP

        @textbox.editable = true
        @markers = []

        @textbox.connect(SEL_RIGHTBUTTONRELEASE) do |sender, sel, event|
          unless event.moved?
            FXMenuPane.new(self) do |menu_pane|
              cpos = sender.cursorPos
              pos = sender.selStartPos

              len = sender.selEndPos - pos

              if len == 0
                i = @textbox.text.index("\n\n")
                unless i.nil?
                  pos = i + 2
                  len = @textbox.text.length - pos
                end
              end

              string2decode = len > 0 ? sender.extractText(pos, len) : ''
              string2decode.extend Watobo::Mixin::Transcoders

              fp_submenu = FXMenuPane.new(self) do |sub|
                eh = FXMenuCommand.new(sub, "File")
                eh.connect(SEL_COMMAND) {
                  insf = FXFileDialog.getOpenFilename(self, "Select file to insert", nil)
                  if insf != "" then
                    if File.exist?(insf) then
                      # puts "Inserting #{insf}"
                      sender.insertText(cpos, "%%File.read('#{insf}').encode('UTF-8').force_encoding('BINARY')%%")
                      highlight_markers
                    end
                  end
                }
                eh = FXMenuCommand.new(sub, "Clipboard Text")
                eh.connect(SEL_COMMAND) {
                  sender.insertText(cpos, '%%getDNDData(FROM_CLIPBOARD, FXWindow.stringType).strip%%')
                  highlight_markers
                }
              end
              FXMenuCascade.new(menu_pane, "Dynamic Content", nil, fp_submenu)

              FXMenuSeparator.new(menu_pane)
              fp_submenu = FXMenuPane.new(self) do |sub|
                target = FXMenuCommand.new(sub, "JSON (ctrl-j)")
                target.connect(SEL_COMMAND) {
                  begin
                    jb = JSON.parse(string2decode)
                    out = JSON.pretty_generate jb
                    @textbox.replaceText(pos, len, out)
                  rescue => bang
                    out = "Could prettify response :(\n\n"
                    out << bang.to_s
                  end
                }
                target = FXMenuCommand.new(sub, "XML (ctrl-x)")
                target.connect(SEL_COMMAND) {
                  begin
                    text = Nokogiri.XML(string2decode, &:noblanks).to_xml
                    #replace_text(sender, doc.to_xml)
                    @textbox.replaceText(pos, len, text)
                  rescue => bang
                    puts bang
                  end

                }

              end
              FXMenuCascade.new(menu_pane, "Prettify", nil, fp_submenu)

              addStringInfo(menu_pane, sender)
              addDecoder(menu_pane, sender)
              addEncoder(menu_pane, sender)
              menu_pane.create
              menu_pane.popup(nil, event.root_x, event.root_y)

              app.runModalWhileShown(menu_pane)
            end

          end
        end

        @textbox.connect(SEL_REPLACED, method(:onTextChanged))
        @textbox.connect(SEL_DELETED, method(:onTextChanged))

        # KEY_Return
        # KEY_Control_L
        # KEY_Control_R
        # KEY_s
        @ctrl_pressed = false

        @textbox.connect(SEL_KEYPRESS) do |sender, sel, event|
          @keystate = false
          if event.code == KEY_Control_L or event.code == KEY_Control_R
            @ctrl_pressed = true
            @keystate = true
          elsif event.code == KEY_Alt_R
            @ctrl_pressed = false
            @keystate = true
            #  @shift_pressed = true if @ctrl_pressed and ( event.code == KEY_Shift_L or event.code == KEY_Shift_R )
          elsif event.code == KEY_F1
            unless event.moved?
              FXMenuPane.new(self) do |menu_pane|
                FXMenuCaption.new(menu_pane, "Hotkeys:")
                FXMenuSeparator.new(menu_pane)
                ["<ctrl-enter> - Send Request",
                 "<ctrl-b> - Encode Base64",
                 "<ctrl-shift-b> - Decode Base64",
                 "<ctrl-u> - Encode URL",
                 "<ctrl-shift-u> - Decode URL",
                 "<ctrl-j> - Prettify JSON"
                ].each do |hk|
                  FXMenuCaption.new(menu_pane, hk)
                end

                menu_pane.create

                menu_pane.popup(nil, event.root_x, event.root_y)
                app.runModalWhileShown(menu_pane)
              end

            end
          elsif @ctrl_pressed
            if event.code == KEY_Return
              notify(:hotkey_ctrl_enter)
              @keystate = true # special handling of KEY_Return, because we don't want a linebreak in textbox.
            else
              notify(:hotkey_ctrl_f) if event.code == KEY_f
              notify(:hotkey_ctrl_s) if event.code == KEY_s
              pos = @textbox.selStartPos
              len = @textbox.selEndPos - pos

              # if nothing is selected we asssume that conversion/beautifying should be
              # performed on full body
              if len == 0
                i = @textbox.text.index("\n\n")
                unless i.nil?
                  pos = i + 2
                  len = @textbox.text.length - pos
                end
              end

              unless len == 0
                text = @textbox.extractText(pos, len)
                rptxt = case event.code
                        when KEY_u
                          CGI::escape(text)
                        when KEY_h
                          CGI::escapeHTML(text)
                        when KEY_H
                          CGI::unescapeHTML(text)
                        when KEY_b
                          Base64.strict_encode64(text)
                        when KEY_U
                          CGI::unescape(text)
                        when KEY_B
                          Base64.decode64(text)
                        when KEY_j
                          begin
                            jb = JSON.parse(text)
                            out = JSON.pretty_generate jb
                          rescue => bang
                            puts bang
                            out = text
                          end
                          out
                        when KEY_z
                          #TODO: Implement UNDO and so a history
                        when KEY_x
                          out = text
                          begin
                           # binding.pry
                            out = Nokogiri.XML(text, &:noblanks).to_xml
                            puts out
                          rescue => bang
                            out = text
                          end
                          out
                        else
                          text
                        end
                text = normalizeText(rptxt)

                @textbox.replaceText(pos, len, text)

                # BUG: setSelection deleted replaced text???
                #@textbox.setSelection(pos, text.length)
              end
              @keystate = false
            end
          else
            #puts "%04x" % event.code
            @keystate = false
          end
          @keystate
        end

        @textbox.connect(SEL_KEYRELEASE) do |sender, sel, event|
          @ctrl_pressed = false if event.code == KEY_Control_L or event.code == KEY_Control_R

        end


      end

      def parseRequest
        begin
          return @textbox.to_request
        rescue SyntaxError, LocalJumpError, NameError => bang
          puts bang
          puts bang.backtrace
          #  puts bang.backtrace if $DEBUG
          notify(:error, "#{$!}")
        rescue => bang
          puts bang
          notify(:error, "Could not parse request: #{$!}")
        end

        return nil
      end


      private

      def highlight_markers
        pattern = '(%%.*?%%)'
        @markers = highlight(pattern)
      end

      def onTextChanged(sender, sel, changed)
        begin
          #dummy = changed.ins
          #  dummy += changed.del

          #pos = changed.pos

          highlight_markers

          #@textbox.setCursorPos(pos)
            # else
            #   @markers.each do |start, len|
            #     if pos >= start and pos <= start + len then
            #       @markers = highlight(pattern)
            #       @textbox.setCursorPos(pos)
            #       break
            #     end
            #   end
            # end

          notify(:text_changed)

        rescue => bang
          puts "!!!ERROR: onTextChanged"
          puts bang
        end
      end
    end

    # -> # module Watobo::Gui
  end
end
