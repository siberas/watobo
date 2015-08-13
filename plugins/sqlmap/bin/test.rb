  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..","..", "lib"))
  $: << inc_path
 
  require 'watobo'
  require 'fox16'
  
  include Fox

  # @private 
module Watobo#:nodoc: all
    module Gui
    @application = FXApp.new('SQLmap', 'Plugin Test')  
 
  %w( load_icons gui_utils load_plugins session_history save_default_settings master_password session_history save_project_settings save_proxy_settings ).each do |l|
  f = File.join("watobo","gui","utils", l)
  puts "SQLMap >> Loading #{f}"
  require f
  
end

require 'watobo/gui/utils/init_icons'

gui_path = File.expand_path(File.join(File.dirname(__FILE__),"..", "..", "..", "lib","watobo", "gui"))

Dir.glob("#{gui_path}/*.rb").each do |cf|
  next if File.basename(cf) == 'main_window.rb' # skip main_window here, because it must be loaded last
  f = File.join("watobo","gui", File.basename(cf))
  puts "Loading >> #{f}"
  require f
end

puts "Loading plugin templates ..."
require 'watobo/gui/templates/plugin'
require 'watobo/gui/templates/plugin2'


require File.join(File.expand_path(File.dirname(__FILE__)), "..","sqlmap")

gui_path = File.join(File.expand_path(File.dirname(__FILE__)),"..", "gui")
puts "="

%w( main options_frame).each do |l|
  puts "Loading >> #{l}"
  require File.join(gui_path, l + ".rb")
end

class TestGui < FXMainWindow
    
def initialize(app)
# Call base class initializer first
super(app, "Test Application", :width => 800, :height => 600)
frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
     
button = FXButton.new(frame, "Open Plugin",:opts => FRAME_THICK|FRAME_RAISED|LAYOUT_FILL_X|LAYOUT_TOP|LAYOUT_LEFT,:padLeft => 10, :padRight => 10, :padTop => 5, :padBottom => 5)
button.connect(SEL_COMMAND) {
  dlg = Watobo::Plugin::Sqlmap::Gui.new(self)  
  if dlg.execute != 0
    puts dlg.to_h.to_yaml
  end  
}
end
    # Create and show the main window
def create
    super                  # Create the windows
    show(PLACEMENT_SCREEN) # Make the main window appear
    dlg = Watobo::Plugin::Sqlmap::Gui.new(self)
    #dlg.set_tab_index 2
    #prefs = { :form_auth_url => "http://www.google.com" }
    #dlg.settings.auth.set prefs
      
    if dlg.execute != 0
        puts dlg.details.to_yaml
    end  
    end
  end
#  application = FXApp.new('LayoutTester', 'FoxTest')  
  TestGui.new(@application)
  @application.create
  @application.run
    end
end 