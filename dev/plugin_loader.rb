inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

%w( load_icons gui_utils load_plugins session_history save_default_settings master_password session_history save_project_settings save_proxy_settings ).each do |l|
  f = File.join("watobo", "gui", "utils", l)
  #puts ">> Loading #{f}"
  require f

end
FXApp.new('Watobo', 'Plugin Loader')


require 'watobo/gui/utils/init_icons'
require 'watobo/gui/mixins/events'
require 'watobo/gui/mixins/gui_settings'

require 'pry'

gui_path = File.expand_path(File.join(Watobo.plugin_path, "..", "lib", "watobo", "gui"))

Dir.glob("#{gui_path}/*.rb").each do |cf|
  next if File.basename(cf) == 'main_window.rb' # skip main_window here, because it must be loaded last
  f = File.join("watobo", "gui", File.basename(cf))
 # puts "Loading >> #{f}"
  require f
end

#puts "Loading plugin templates ..."
require 'watobo/gui/templates/plugin'
require 'watobo/gui/templates/plugin2'
require 'watobo/gui/templates/plugin_base'
require 'watobo/gui/plugin_board'
require 'watobo/gui/utils/load_plugins'
require 'watobo/gui/subframes/egress_handler_selection'


require File.join(File.dirname(__FILE__), 'plugin_loader', 'gui','main')

Watobo.dev_mode
