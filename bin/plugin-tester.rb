inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'fox16'
include Fox

require 'watobo'
require 'watobo/dev/plugin_loader'

module Watobo
  module Gui
    PluginLoader.new
    application.create
    application.run
  end
end
