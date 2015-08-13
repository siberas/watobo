# @private 
module Watobo#:nodoc: all
  module Plugin
    module Crawler
      class Gui
        class SettingsTabBook < FXTabBook
          attr :hooks, :general, :log_viewer, :auth, :scope
          
          
          
          def initialize(owner)
            #@tab = FXTabBook.new(self, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            super(owner, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
            FXTabItem.new(self, "General", nil)
            # frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
            @general = GeneralSettingsFrame.new(self)
            
            FXTabItem.new(self, "Scope", nil)
            @scope = ScopeFrame.new(self)
            
            FXTabItem.new(self, "Auth", nil)
            @auth = AuthFrame.new(self)

            
            FXTabItem.new(self, "Hooks", nil)
            @hooks = HooksFrame.new(self)
            
            FXTabItem.new(self, "Log", nil)
            frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_THICK|FRAME_RAISED)
            @log_viewer = Watobo::Gui::LogViewer.new(frame, :append, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
            
            self.connect(SEL_COMMAND){
              @hooks.selected if self.current == 3
            }
          end
        end
      end
    end
  end
end