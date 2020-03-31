# @private 
module Watobo#:nodoc: all::Plugin
  module Plugin
    class Sequencer < Watobo::PluginBase
      plugin_name "Sequencer"
      description "Create and run request sequences, e.g. for complex API request chains."
      load_libs
      load_gui :main, :create_element_dlg, :elements_frame, :list_frame, :details_frame, :var_frame, :request_frame, :post_script_frame
    end
  end
end

