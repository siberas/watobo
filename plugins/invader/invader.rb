# @private
# https://www.synopsys.com/content/dam/synopsys/sig-assets/whitepapers/exploiting-the-java-deserialization-vulnerability.pdf
module Watobo#:nodoc: all::Plugin
  module Plugin
    class Invader < Watobo::PluginBase
      plugin_name "Invader"
      description "Fire custom payloads on targets."
      load_libs
      load_gui
    end
  end
end

