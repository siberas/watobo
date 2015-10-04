# @private 
module Watobo#:nodoc: all::Plugin
  module Plugin
    class AEM < Watobo::PluginBase
      plugin_name "AEM"
      description "Adobe Experience Manager Enumerator"
      load_libs
      load_gui :main, :tree_view
    end
  end
end

