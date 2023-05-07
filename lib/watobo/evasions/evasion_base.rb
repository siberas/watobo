module Watobo
  module EvasionHandlers
    class EvasionHandlerBase

      def self.prio(prio)
        @prio = prio
      end

      def prio
        self.class.instance_variable_get("@prio") || 10
      end

      def run
        raise "run method must be set by EvasionHandler"
      end

      def name
        self.class.to_s.gsub(/^.*::/, '')
      end

    end
  end
end