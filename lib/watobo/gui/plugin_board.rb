# @private 
module Watobo#:nodoc: all
  module Gui
    class PluginBoard < FXVerticalFrame
      include Watobo::Gui::Icons
      def updateBoard()

        return false unless Watobo::Gui.plugins.first.respond_to? :plugin_name
        begin
          @matrix.each_child do |child|
            @matrix.removeChild(child)
          end

          loaded = []

          Watobo::Gui.plugins.each do |p|
            plugin_name = p.respond_to?(:get_plugin_name) ? p.get_plugin_name : p.plugin_name
            next if loaded.include? plugin_name
            loaded << plugin_name
            icon =p.respond_to?(:icon) ? p.icon : p.gui.icon
            pbtn = FXButton.new( @matrix, "\n" + plugin_name, icon, nil, 0,
            :opts => ICON_ABOVE_TEXT|FRAME_RAISED|FRAME_THICK|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT|LAYOUT_RIGHT,
            :width => 80, :height => 80)
            pbtn.create

            pbtn.connect(SEL_COMMAND) {
              gui =  p.respond_to?(:create) ? p : p.gui
              gui.create
              gui.show(Fox::PLACEMENT_SCREEN)
            # gui.updateView()
            }

            pbtn.connect(SEL_RIGHTBUTTONPRESS) { |sender, sel, event|
              description = nil
              description = p.get_description if p.respond_to?(:get_description)
              description = "No description available." if description.nil?

              plugin_name = p.respond_to?(:get_plugin_name) ? p.get_plugin_name : p.plugin_name
              unless event.moved?
                FXMenuPane.new(self) do |menu_pane|
                  #title = FXMenuCaption.new(menu_pane, "Description: #{plugin_name}")
                  #title.backColor = 'red'
                   #f = FXVerticalFrame.new(menu_pane, :opts=>LAYOUT_FILL_X|LAYOUT_FILL_Y)
                  t = FXLabel.new(menu_pane, "#{plugin_name}")
                 # t.justify = JUSTIFY_LEFT
                  t.font = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD)

                  f = FXVerticalFrame.new(menu_pane, :opts=>LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_SUNKEN)
                  FXLabel.new(f, description).justify = JUSTIFY_LEFT

                  menu_pane.create
                  menu_pane.popup(nil, event.root_x, event.root_y)
                  app.runModalWhileShown(menu_pane)
                end
              end
            }

            frame = FXFrame.new(@matrix, :opts => FRAME_NONE|LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT, :width => 80, :height => 80)
            frame.backColor = FXColor::White
          end

          @plugin_frame.recalc
          @plugin_frame.update

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end

      def initialize(parent)
        begin

          super(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
          # db_title = FXLabel.new(self, "PLUGIN-BOARD", :opts => LAYOUT_LEFT)
          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
          main.backColor = FXColor::White

          frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
          frame.backColor = FXColor::White
          title_icon = FXButton.new(frame, '', ICON_PLUGIN, :opts => FRAME_NONE)
          title_icon.backColor = FXColor::White

          @font_title = FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT)
          title  = FXLabel.new(frame, "Plugin-Board", nil, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          title.backColor = FXColor::White
          title.setFont(@font_title)
          title.justify = JUSTIFY_LEFT|JUSTIFY_CENTER_Y

          @plugin_frame = FXVerticalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)

          @plugin_frame.backColor = FXColor::White

          @matrix = FXMatrix.new(@plugin_frame, 7, :opts => MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
          @matrix.backColor = FXColor::White
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      # update(nil)
      end
    end
  end
end
