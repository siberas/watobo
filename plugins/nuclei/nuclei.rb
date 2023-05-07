# @private
module Watobo#:nodoc: all::Plugin
  module Plugin
    class Nuclei < Watobo::PluginBase
      plugin_name "Nuclei"
      description "Scanner for Nuclei-Templates"
      load_libs
      load_gui :main, :status_frame, :tree_list_frame, :request_frame, :template_info_frame, :options_frame
    end
  end
end

