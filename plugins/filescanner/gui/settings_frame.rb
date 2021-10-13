# @private
#require_relative 'target_frame'
module Watobo #:nodoc: all
  module Plugin
    class Filescanner
      class Gui
        class SettingsFrame < FXVerticalFrame

          include Subscriber

          def settings=(s)

          end

          def settings
            db_file = case @finder_tab.current
                      when 1
                        @db_select_frame.get_db_name
                      else
                        @search_name_dt.value
                      end


            s = {
                db_file: db_file,
                test_all_dirs: @test_all_dirs.checked?,
                egress_handler: @egress_handler_frame.egress_handler,
                scanlog_name: @scanlog_name_dt.value,
                run_passive_checks: false,
                evasion_level: @el_dt.value,
                file_extensions: (@append_extensions_cb.checked? ? @extensions_text.text.split(';') : []),
                evasion_extensions: ( @el_dt.value > 0 ? @l1_txt.text.split : [] )
            }
            s
          end

          def initialize(ctrl, owner, opts)
            opts[:padding] = 0
            super(owner, opts)

            @ctrl = ctrl
            @db_list = []
            @db_name = ""

            @finder_tab = FXTabBook.new(self, nil, 0, opts: LAYOUT_FILL_X, padding: 0)

            FXTabItem.new(@finder_tab, "Filename", nil)
            frame = FXVerticalFrame.new(@finder_tab, :opts => LAYOUT_FILL_X | FRAME_RAISED)
            @search_name_dt = FXDataTarget.new("")

            @dbfile_text = FXTextField.new(frame, 30,
                                           :target => @search_name_dt, :selector => FXDataTarget::ID_VALUE,
                                           :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_FILL_X)
            @dbfile_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)


            FXTabItem.new(@finder_tab, "Database", nil)
            @db_select_frame = DBSelectFrame.new(@finder_tab, @db_list, :opts => FRAME_THICK | FRAME_RAISED | LAYOUT_FILL_X)

            unless @db_name.empty?
              @db_select_frame.select_db @db_name
              @finder_tab.current = 1
            end

            group_box = FXGroupBox.new(self, "Recursive", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            @test_all_dirs = FXCheckButton.new(group_box, "enable recursive scan of all directories", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_LEFT)
            @test_all_dirs.setCheck(false)

            group_box = FXGroupBox.new(self, "Egress Handler", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            @egress_handler_frame = Watobo::Gui::SubFrames::EgressHandlerSelection.new(group_box)


            @fmode_dt = FXDataTarget.new(0)
            group_box = FXGroupBox.new(self, "Extensions", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            mode_frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X)
            @append_slash_cb = FXCheckButton.new(mode_frame, "append /", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP | LAYOUT_FILL_Y)

            @append_extensions_cb = FXCheckButton.new(mode_frame, "append file extensions", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP | LAYOUT_FILL_Y)
            frame = FXVerticalFrame.new(mode_frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
            @extensions_text = FXText.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | TEXT_WORDWRAP)
            ext = "svc;bak;php;asp;aspx;tgz;tar.gz;gz;tmp;temp;old;_"

            @extensions_text.setText(ext)


            #------------------------------------------------------------------------------------------------------------------------------
            #  F i l t e r   E v a s i o n s
            #
            @el_dt = FXDataTarget.new(0)
            @el_dt.connect(SEL_COMMAND) do
              @rb_el0.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @rb_el1.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @rb_el2.handle(self, FXSEL(SEL_UPDATE, 0), nil)
              @switcher.current = @el_dt.value
            end
            group_box = FXGroupBox.new(self, "Evasion Level", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            hframe = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP, :padding => 0)
            vframe = FXVerticalFrame.new(hframe, :opts => LAYOUT_FILL_X)
            @switcher = FXSwitcher.new(hframe, LAYOUT_FILL_X | LAYOUT_FILL_Y)

            #frame = FXHorizontalFrame.new(vframe, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP, :padding => 0)
            @rb_el0 = FXRadioButton.new(vframe, "None", @el_dt, FXDataTarget::ID_OPTION)
            #frame = FXHorizontalFrame.new(vframe, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP, :padding => 0)
            @rb_el1 = FXRadioButton.new(vframe, "Level 1", @el_dt, FXDataTarget::ID_OPTION + 1)
            #@l1_btn = FXButton.new(frame, "Settings", nil, nil, 0, FRAME_RAISED|FRAME_THICK)
            #frame = FXHorizontalFrame.new(vframe, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP, :padding => 0)
            # TODO: create level 2
            @rb_el2 = FXRadioButton.new(vframe, "Level 2", @el_dt, FXDataTarget::ID_OPTION + 2)
            @rb_el2.disable
            #@l2_btn = FXButton.new(frame, "Settings", nil, nil, 0, FRAME_RAISED|FRAME_THICK)

            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "No evasion techniques will be applied")

            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "Enter space separated chars/strings to append")
            frame = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN | FRAME_THICK, :padding => 0)
            @l1_txt = FXText.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | TEXT_WORDWRAP)
            @l1_txt.setText("/; ?y=x.png ?debug=true")

            frame = FXVerticalFrame.new(@switcher, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
            FXLabel.new(frame, "Not yet available")

            #------------------------------------------------------------------------------------------------------------------------------
            #  S C A N   L O G   S E T T I N G S
            #
            group_box = FXGroupBox.new(self, "Logging", LAYOUT_SIDE_TOP | FRAME_GROOVE | LAYOUT_FILL_X, 0, 0, 0, 0)
            frame = FXVerticalFrame.new(group_box, :opts => LAYOUT_FILL_X)
            #frame = FXHorizontalFrame.new(group_box, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            # @enable_logging_cb = FXCheckButton.new(mode_frame, "enable", nil, 0, ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP | LAYOUT_FILL_Y)
            @enable_logging_cb = FXCheckButton.new(frame, "enable", nil, 0, JUSTIFY_LEFT | JUSTIFY_TOP | ICON_BEFORE_TEXT | LAYOUT_SIDE_TOP)

            @scanlog_name_dt = FXDataTarget.new('')
            # @scanlog_name_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())

            scanlog_frame = FXHorizontalFrame.new(frame, :opts => LAYOUT_FILL_X | LAYOUT_SIDE_TOP)
            @scanlog_dir_label = FXLabel.new(scanlog_frame, "Scan Name:")
            @scanlog_name_text = FXTextField.new(scanlog_frame, 20,
                                                 :target => @scanlog_name_dt, :selector => FXDataTarget::ID_VALUE,
                                                 :opts => TEXTFIELD_NORMAL | LAYOUT_FILL_COLUMN | LAYOUT_FILL_X)

            @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            unless @enable_logging_cb.checked?
              @scanlog_name_text.enabled = false
              @scanlog_name_text.backColor = @scanlog_name_text.parent.backColor
            end

            @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)

            unless @enable_logging_cb.checked?
              @scanlog_name_text.enabled = false
              @scanlog_name_text.backColor = @scanlog_name_text.parent.backColor
            end

            @enable_logging_cb.checkState = false

            @enable_logging_cb.connect(SEL_COMMAND) do |sender, sel, item|
              if @enable_logging_cb.checked? then
                @scanlog_name_text.enabled = true
                @scanlog_name_text.backColor = FXColor::White
              else
                @scanlog_name_text.enabled = false
                @scanlog_name_text.backColor = @scanlog_name_text.parent.backColor
              end
            end


            # updateView()
          end


        end
      end
    end
  end
end

