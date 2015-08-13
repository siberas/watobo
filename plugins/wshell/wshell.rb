# @private 
module Watobo#:nodoc: all::Plugin
  module Plugin
    class WShell < Watobo::PluginBase
      plugin_name "WShell"
      description "With WShell you can execute ruby commands in the context of WATOBO.\nVery useful for advanced analysis of conversations or debugging purposes - or simply to explore WATOBO."
      load_libs
      load_gui :main
    end
  end
end

