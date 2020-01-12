module Watobo
  module Plugin
    class Invader
      Tweaks = []

      class Tweak
        attr :type
        attr :func
        attr :info
        attr_accessor :enabled

        attr_accessor :enabled

        def is_action?
          true
        end

        def enabled?
          @enabled
        end

        def initialize(proc, prefs)
          @func = proc
          @type = prefs[:type] || "undefined"
          @info = prefs[:info] || "undefined"
          @enabled = true
        end

      end

    end
  end
end



