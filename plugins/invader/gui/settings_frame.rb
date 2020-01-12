=begin
* passive-checks
* egress-handler
* save scan
* grep/extract (separate frame??)
=end

module Watobo #:nodoc: all
  module Plugin
    class Invader
      class Gui

        class SettingsFrame < FXVerticalFrame

          def scanlog_name
            return '' unless @logScanChats.checked?
            @scanlog_name_dt.value.strip
          end

          def initialize(owner, opts)
            super(owner, opts)

            gbox = FXGroupBox.new(self, "Logging", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            frame = FXHorizontalFrame.new(gbox,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            @logScanChats = FXCheckButton.new(frame, "enable", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @logScanChats.checkState = false
            @logScanChats.connect(SEL_COMMAND) do |sender, sel, item|
              if @logScanChats.checked? then
                @scanlog_name_text.enabled = true
                @scanlog_dir_label.enabled = true
                #  @scanlog_dir_btn.enable
              else
                @scanlog_name_text.enabled = false
                @scanlog_dir_label.enabled = false
                # @scanlog_dir_btn.disable
              end
            end

            @scanlog_name_dt = FXDataTarget.new('')
            # @scanlog_name_dt.value = @project.scanLogDirectory() if File.exist?(@project.scanLogDirectory())
            @scanlog_dir_label = FXLabel.new(frame, "Scan-Name:" )

            @scanlog_name_text = FXTextField.new(frame, 20,
                                                 :target => @scanlog_name_dt, :selector => FXDataTarget::ID_VALUE,
                                                 :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_FILL_X)
            @scanlog_name_text.handle(self, FXSEL(SEL_UPDATE, 0), nil)
            @scanlog_name_text.enabled = false
            @scanlog_dir_label.enabled = false

            gbox = FXGroupBox.new(self, "Passive Checks", LAYOUT_SIDE_TOP|FRAME_GROOVE|LAYOUT_FILL_X, 0, 0, 0, 0)
            frame = FXHorizontalFrame.new(gbox,:opts => LAYOUT_FILL_X|LAYOUT_SIDE_TOP)
            @passive_checks = FXCheckButton.new(frame, "enable", nil, 0, JUSTIFY_LEFT|JUSTIFY_TOP|ICON_BEFORE_TEXT|LAYOUT_SIDE_TOP)
            @passive_checks.checkState = false


          end
        end
      end
    end
  end
end
