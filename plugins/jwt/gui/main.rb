# @private
module Watobo #:nodoc: all
  module Plugin
    class JWT
      include Watobo::Settings

      class Gui < Watobo::PluginGui

        window_title "JSON Web Token Analyzer"
        icon_file "jwt.ico"


        def initialize(chat=nil)

          super(:width => 600, :height => 800)

          @settings = Watobo::Plugin::JWT::Settings

          @jwt_head = ''
          @jwt_payload = ''
          @jwt_signature = ''

          @results = []

          @settings.export_path ||= Watobo.workspace_path


          begin
            main_frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            matrix = FXMatrix.new(main_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)

            FXLabel.new(matrix, "Token:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)

            @tabBook = FXTabBook.new(matrix, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            @raw_tab = FXTabItem.new(@tabBook, "RAW", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            FXLabel.new(frame, 'Enter your raw jwt-token here')
            @raw_txt = FXTextField.new(frame, 80, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            @raw_txt.connect(SEL_CHANGED) {|sender, sel, index|
              puts '* raw text changed'
              parse_raw
            }


            @chat_tab = FXTabItem.new(@tabBook, "Chat-ID", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            FXLabel.new(frame, 'Enter your chat-id here')
            @chatid_txt = FXTextField.new(frame, 80, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            #

            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "Header:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @raw_header_cb = FXCheckButton.new(frame, "raw", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
            @raw_header_cb.connect(SEL_COMMAND) {|sender, sel, index|
              update_fields
            }
            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_MIN_HEIGHT|FRAME_SUNKEN|FRAME_THICK, :height => 80, :padding => 0)
            @head_txt = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            # FXButton.new(matrix, "Select").connect(SEL_COMMAND) { select_key_file }

            #

            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "Payload:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @raw_payload_cb = FXCheckButton.new(frame, "raw", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
            @raw_payload_cb.connect(SEL_COMMAND) {|sender, sel, index|
              update_fields
            }
            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|LAYOUT_MIN_HEIGHT|FRAME_SUNKEN|FRAME_THICK, :height => 400, :padding => 0)
            @payload_txt = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            # FXButton.new(matrix, "Select").connect(SEL_COMMAND) { select_key_file }

            #  matrix = FXMatrix.new(main_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
            FXLabel.new(matrix, "Signature:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @signature_txt = FXTextField.new(matrix, 83, :target => nil, :selector => 0, :opts => TEXTFIELD_NORMAL)

            # create new token and copy to clipboard
            FXButton.new(matrix, "Create", :opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_Y|LAYOUT_FILL_X).connect(SEL_COMMAND) {create_token}
            frame = FXHorizontalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|PACK_UNIFORM_WIDTH)
            @recalc_cb = FXCheckButton.new(frame, "recalc signature", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
            @recalc_cb.disable

            @create_raw_cb = FXCheckButton.new(frame, "raw", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
            @create_raw_cb.check = true

            frame = FXVerticalFrame.new(main_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            token_frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding => 0)
            @token_txt = FXText.new(token_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)


            unless chat.nil?
              @tabBook.current = 1
              @chatid_txt.setText chat.id.to_s
              jwt = get_token_from_chat(chat)

              unless jwt.nil?
                @raw_txt.setText jwt unless jwt.nil?
                update_fields
              end
            end


          rescue => bang
            puts bang
            puts bang.backtrace
            exit
          end

        end

        private

        def parse_raw
          @raw_txt.backColor = FXColor::White
          jwt = @raw_txt.text.strip
          jhb64, jpb64, jsb64 = jwt.split('.')
          return false if jhb64.nil? | jpb64.nil? | jsb64.nil?
          begin
            jwt_head = Base64.urlsafe_decode64(jhb64)
            jwt_payload = Base64.urlsafe_decode64(jpb64)
            jwt_signature = jsb64
            @jwt = jwt
          rescue => bang
            @raw_txt.backColor = FXColor::Red
            jwt_head = ''
            jwt_payload = ''
            jwt_signature = ''
            @jwt = nil
          end

          @jwt_head = jwt_head
          @jwt_payload = jwt_payload
          @jwt_signature = jwt_signature

          update_fields
        end

        def update_fields
          begin
            head_bak = @head_txt.text
            payload_bak = @payload_txt.text
            sig_bak = @signature_txt.text

          unless @raw_header_cb.checked?
            @head_txt.setText(JSON.pretty_generate(JSON.parse(@jwt_head)).to_s)
          else
            @head_txt.setText(@jwt_head)
          end

          unless @raw_payload_cb.checked?
            @payload_txt.setText(JSON.pretty_generate(JSON.parse(@jwt_payload)).to_s)
          else
            @payload_txt.setText(@jwt_payload)
          end

          @signature_txt.setText(@jwt_signature)
          rescue => bang
            @raw_txt.backColor = FXColor::Red
            puts bang
            @head_txt.text = head_bak
            @payload_txt.text = payload_bak
            @signature_txt.text = sig_bak
          end

        end

        def get_token_from_chat(chat)
          bearer = chat.request.headers(' Bearer ')[0]
          @jwt = nil
          unless bearer.nil?
            @jwt = bearer.match(/Bearer (.*)/)[1]
            jhb64, jpb64, jsb64 = @jwt.split('.')
            @jwt_head = Base64.urlsafe_decode64(jhb64)
            @jwt_payload = Base64.urlsafe_decode64(jpb64)
            @jwt_signature = jsb64
          end
          @jwt
        end

        def create_token
          token = []
          begin
            #token << Base64.urlsafe_encode64(JSON.parse(@head_txt.text).to_s)
            token << Base64.urlsafe_encode64(@head_txt.to_s)
            #token << Base64.urlsafe_encode64(JSON.parse(@payload_txt.text).to_s)
            token << Base64.urlsafe_encode64(@payload_txt.to_s)
            token << @signature_txt.text
            @token_txt.setText(token.join('.').gsub(/=+/,''))
          rescue => bang
            @token_txt.setText(bang.to_s)
          end

        end


        def add_update_timer(ms)
          @timer = FXApp.instance.addTimeout(500, :repeat => true) {
            unless @scanner.nil?
              if @pbar.total > 0
                @pbar.progress = @scanner.sum_progress
              end

              if @scanner.finished?
                @scanner = nil
                # logger("Scan Finished!")
                @pbar.progress = 0
                @pbar.total = 0
                @pbar.barColor = 'grey' #FXRGB(255,0,0)
                FXApp.instance.removeTimeout(@timer)

                @result_frame.update

              end
            end
          }
        end


      end
    end
  end
end