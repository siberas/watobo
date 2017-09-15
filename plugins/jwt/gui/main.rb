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

            matrix = FXMatrix.new(main_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)

            FXLabel.new(matrix, "Token:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)

            @tabBook = FXTabBook.new(matrix, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT, :padding => 0)
            @raw_tab = FXTabItem.new(@tabBook, "RAW", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_Y|FRAME_RAISED)
            FXLabel.new(frame, 'Enter your raw jwt-token here')
            @raw_txt = FXTextField.new(frame, 80, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            @raw_txt.connect(SEL_CHANGED) {|sender, sel, index|
              parse_raw
            }


            @chat_tab = FXTabItem.new(@tabBook, "Chat-ID", nil)
            frame = FXVerticalFrame.new(@tabBook, :opts => LAYOUT_FILL_Y|LAYOUT_FILL_Y|FRAME_RAISED)
            FXLabel.new(frame, 'Enter your chat-id here')
            @chatid_txt = FXTextField.new(frame, 80, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT)

            #

            FXLabel.new(matrix, "Header:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN|FRAME_THICK, :height => 80, :padding => 0)
            @head_txt = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            # FXButton.new(matrix, "Select").connect(SEL_COMMAND) { select_key_file }

            #

            FXLabel.new(matrix, "Payload:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            frame = FXVerticalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|FRAME_SUNKEN|FRAME_THICK, :height => 400, :padding => 0)
            @payload_txt = FXText.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
            # FXButton.new(matrix, "Select").connect(SEL_COMMAND) { select_key_file }

            #  matrix = FXMatrix.new(main_frame, 2, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
            FXLabel.new(matrix, "Signature:", nil, LAYOUT_TOP|JUSTIFY_RIGHT)
            @signature_txt = FXTextField.new(matrix, 83, :target => nil, :selector => 0, :opts => TEXTFIELD_NORMAL)

            # create new token and copy to clipboard
            FXButton.new(matrix, "Create",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_Y|LAYOUT_FILL_X).connect(SEL_COMMAND) {create_token}
            frame = FXHorizontalFrame.new(matrix, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED|PACK_UNIFORM_WIDTH)
            @recalc_cb = FXCheckButton.new(frame, "recalc signature", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)
            @pack_cb = FXCheckButton.new(frame, "pack as is", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT)

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
          jhb64, jpb64, jsb64 = @raw_txt.text.strip.split('.')
          return false if jhb64.nil? | jpb64.nil? | jsb64.nil?
          begin
            jwt_head = JSON.parse(Base64.decode64(jhb64))
            jwt_payload = JSON.parse(Base64.decode64(jpb64))
            jwt_signature = jsb64
          rescue => bang
            return false
          end

          @jwt_head = jwt_head
          @jwt_payload = jwt_payload
          @jwt_signature = jwt_signature

          update_fields
        end

        def update_fields
          @head_txt.setText(JSON.pretty_generate(@jwt_head))
          @payload_txt.setText(JSON.pretty_generate(@jwt_payload))
          @signature_txt.setText(@jwt_signature)
        end

        def get_token_from_chat(chat)
          bearer = chat.request.headers(' Bearer ')[0]
          unless bearer.nil?
            jwt = bearer.match(/Bearer (.*)/)[1]
            jhb64, jpb64, jsb64 = jwt.split('.')
            @jwt_head = JSON.parse(Base64.decode64(jhb64))
            @jwt_payload = JSON.parse(Base64.decode64(jpb64))
            @jwt_signature = jsb64
          end
          bearer
        end

        def create_token
          token = []
          begin
            token << Base64.encode64(JSON.parse(@head_txt.text).to_s)
            token << Base64.encode64(JSON.parse(@payload_txt.text).to_s)
            token << @signature_txt.text
            @token_txt.setText(token.join('.'))
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