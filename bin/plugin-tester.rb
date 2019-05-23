inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'fox16'
include Fox

require 'watobo'
require 'watobo/plugin_loader'

$plugin_filter = ARGV[0] ? ARGV[0] : ''
module Watobo
  module Gui
    PluginLoader.new $plugin_filter
    application.create
    application.run
  end
end
