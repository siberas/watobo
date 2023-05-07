# @private
module Watobo#:nodoc: all::Plugin
  module Plugin
    class Filescanner < Watobo::PluginBase
      plugin_name "File Scanner"
      description "Scan for single or multiple files."
      load_libs
      load_gui :main, :status_frame, :settings_frame, :dbselect_frame, :request_frame
    end
  end
end

