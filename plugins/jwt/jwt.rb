# @private
module Watobo#:nodoc: all::Plugin
  module Plugin
    class JWT < Watobo::PluginBase
      plugin_name "JWT Analyzer"
      description "JWT Creator/Parser/Analyzer/Verifier"
      load_libs
      load_gui :main
        #, :targets, :result_tree
    end
  end
end

