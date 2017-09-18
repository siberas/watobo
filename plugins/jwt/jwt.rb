# @private
module Watobo#:nodoc: all::Plugin
  module Plugin
    class JWT < Watobo::PluginBase
      plugin_name "JWT Analyzer"
      description "Run specific tests on a list of targets. Good for bughunting."
      load_libs
      load_gui :main
        #, :targets, :result_tree
    end
  end
end

