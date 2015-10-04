# @private 
module Watobo#:nodoc: all
  module Plugin
    class Sqlmap
      class SettingsTabBook < FXTabBook
        attr :general
        def initialize(owner)
          #@tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
          super(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
          FXTabItem.new(self, "General", nil)
          @general = OptionsFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

        #   FXTabItem.new(self, "Advanced", nil)
        #   frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        #   FXTabItem.new(self, "Log", nil)
        #   frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_RAISED)
        #   @log_viewer = Watobo::Gui::LogViewer.new(frame, :append, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
        end
      end

      class Gui < Watobo::Plugin2
        icon_file "sqlmap.ico"

        include Watobo::Constants
        include Responder
        #  include Watobo::Plugin::Crawler::Constants
        def updateView

        end

        def initialize(owner, project=nil, chat=nil)
          super(owner, "SQLMap", project, :opts => DECOR_ALL, :width=>800, :height=>600)
          @plugin_name = "SQLMap"

          FXMAPFUNC(SEL_COMMAND, ID_ACCEPT, :onAccept)
          
          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          matrix = FXMatrix.new(main, 3, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
          FXLabel.new(matrix, "sqlmap path:")
          # frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          #  FXLabel.new(frame, "http://")
          @binary_path_txt = FXTextField.new(matrix, 60, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
          bin_path = Watobo::Plugin::Sqlmap.binary_path
          bin_path ="not defined" if bin_path.empty?
          @binary_path_txt.text = bin_path

          @change_btn = FXButton.new(matrix, "...", :opts => BUTTON_DEFAULT|BUTTON_NORMAL )
          @change_btn.enable

          @change_btn.connect(SEL_COMMAND){
            open_path = nil
            unless @binary_path_txt.text.empty?
              dir_name = File.dirname(@binary_path_txt.text)
              unless dir_name.empty?
              open_path = dir_name unless File.exist? dir_name
              end
            end
            bin_path_old = @binary_path_txt.text
            bin_path = FXFileDialog.getOpenFilename(self, "Select SQLmap Path", open_path)
            unless bin_path.empty?
              @binary_path_txt.text = bin_path
            else              
              @binary_path_txt.text = bin_path_old
              
            end
            if File.exist? @binary_path_txt.text
            Watobo::Plugin::Sqlmap.set_binary_path bin_path
              @accept_btn.enable
            else
              Watobo::Plugin::Sqlmap.set_binary_path ''
              @accept_btn.disable 
            end
          }

          FXLabel.new(matrix, "temp directory:")
          # frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
          #  FXLabel.new(frame, "http://")
          @output_path_txt = FXTextField.new(matrix, 60, nil, 0, :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
          @output_path_txt.text = Watobo::Plugin::Sqlmap.tmp_dir

          @output_path_btn = FXButton.new(matrix, "...", :opts => BUTTON_DEFAULT|BUTTON_NORMAL )
          @output_path_btn.enable

          @output_path_btn.connect(SEL_COMMAND){
            output_path = FXFileDialog.getOpenDirectory(self, "Select Temp Directory", Watobo::Plugin::Sqlmap.tmp_dir)

            #puts ">> #{output_path}"
            unless output_path.empty?
            @output_path_txt.text = output_path
            Watobo::Plugin::Sqlmap.set_tmp_dir output_path
            end
          }

          @settings_tab = SettingsTabBook.new(main)

          unless chat.nil?
          @settings_tab.general.request = chat.request
          end

          # @log_viewer = @settings_tabbook.log_viewer

          buttons = FXHorizontalFrame.new(main, :opts => LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|PACK_UNIFORM_WIDTH,
          :padLeft => 40, :padRight => 40, :padTop => 20, :padBottom => 20)
          @accept_btn = FXButton.new(buttons, "&Start", nil, self, ID_ACCEPT,
          FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
          @accept_btn.disable
          @accept_btn.enable unless Watobo::Plugin::Sqlmap.binary_path.empty?
          # Cancel
          FXButton.new(buttons, "&Cancel", nil, self, ID_CANCEL,
          FRAME_RAISED|FRAME_THICK|LAYOUT_RIGHT|LAYOUT_CENTER_Y)
        # Configuration Categories
        # =
        # Request
        # Optimization
        # Detection
        # Techniques
        # Fingerprint
        # Enumeration
        
        
            
            @accept_btn.disable if @settings_tab.general.request.empty?
            @settings_tab.general.subscribe(:request_changed){
              if @settings_tab.general.request.empty?
                @accept_btn.disable 
              else
                @accept_btn.enable
              end
            }
        end

        private

        def create_request_file
          fname = "sqlmap_" + Time.now.to_i.to_s + ".req"
          begin
            file = File.join(@output_path_txt.text, fname)
            File.open(file, "w"){ |fh|
              fh.puts @settings_tab.general.request
            }
            return file
          rescue => bang
            puts bang
            puts bang.backtrace
            return nil
          end
        end

        def sqlmap_command(file)
          sqlmap = []

          sqlmap << @binary_path_txt.text
          sqlmap << "-r #{file}"
          sqlmap << "--level #{@settings_tab.general.level}"
          sqlmap << "--risk #{@settings_tab.general.risk}"
          sqlmap << "--technique #{@settings_tab.general.technique}"
          sqlmap << @settings_tab.general.manual_options

          sqlmap_cmd = sqlmap.join(" ")
        end

        def linux_command(file)
          # /usr/bin/xterm -hold -e "script -c \"ls -alh\" test234.out"
          xterm_bin = "/usr/bin/xterm"
          return false unless File.exist? xterm_bin
          command = "cd #{@output_path_txt.text} && #{xterm_bin} -hold -e \""
          script_cmd = "#{sqlmap_command(file)}"
          command << script_cmd
          command << '"'
          puts command
          command
        end
        
        def win_command(file)
        # start "sqlmap" /WAIT /D c:\tools dir
          command = ""

          out_file = file.gsub(/\.req/, ".out")
          start_path = "#{@output_path_txt.text}"
          start_path.gsub!(/\//,'\\')
          
          script_cmd = "start \"SQLmap\" /D #{start_path} /WAIT cmd.exe /k \"#{sqlmap_command(file)}\""
          command << script_cmd
          command << '"'
          puts command
          command
        end

        def run_sqlmap(file)
          command = case RUBY_PLATFORM
          when /linux|bsd|solaris|hpux|darwin/
            linux_command file
          when /mswin|mingw|bccwin/
            win_command file
          end
          Thread.new(command){ |cmd|
            system(cmd)
          }

        end

        def onAccept(sender, sel, event)
          if @settings_tab.general.request.empty?
            puts "No Request Defined!"
          end

          rf = create_request_file
          puts "Start SQLMap with file #{rf}"
          run_sqlmap(rf)
        #getApp().stopModal(self, 1)
        #self.hide()
        #return 1

        end

      end
    end
  end
end
