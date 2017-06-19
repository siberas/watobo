# @private
module Watobo #:nodoc: all
  module Plugin
    class Sniper
      class Gui
        class TargetsFrame < FXVerticalFrame

          def targets
            @targets_list.to_s.split("\n").map{|t| t.strip }
          end

          def initialize(parent, opts)
            super(parent, opts)

            @settings = Watobo::Plugin::Sniper::Settings

            targets_gb = FXGroupBox.new(self, "Target URLs", FRAME_GROOVE|LAYOUT_FILL_X|LAYOUT_FILL_Y, 0, 0, 0, 0)
            frame = FXHorizontalFrame.new(targets_gb, :opts => LAYOUT_FILL_X)
            @import_btn = FXButton.new(frame, "Import")
            FXLabel.new(frame, 'or enter manually one each line')

            @import_btn.connect(SEL_COMMAND){ import_targets }

            targets_frame = FXVerticalFrame.new(targets_gb, :opts => FRAME_NONE|LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN, :padding => 0)
            @targets_list = FXText.new(targets_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)


          end

          private

          def is_url?(url_str)
              begin
                return false unless url_str.strip =~ /^https?:\/\//
                url = URI.parse(url_str.strip)
                # puts url.host.class
                return true unless url.host.nil?
                return false
              rescue => bang
                puts bang if $DEBUG
                return false
              end

          end


          def import_targets()
            filename = FXFileDialog.getOpenFilename(self, "Select Targets", @settings.last_path )
            if filename != "" then
                @settings.last_path = File.dirname(filename) + '/'
                @settings.save

                valid = 0
                offline = 0

                File.readlines(filename).each do |l|
                  l.strip!
                  next if l.empty?

                  if is_url?(l)


                    request = Request.new(l)

                    if Watobo::HTTPSocket.siteAlive?(request)
                      @targets_list.appendText("#{l}\n")
                      valid += 1
                    else
                      offline += 1
                    end

                  end
                end

                FXMessageBox.information(self,MBOX_OK,"Import Target URLs", "Found #{valid} valid URLs.\n#{offline} were offline.")

            end
          end
        end
      end
    end
  end
end
