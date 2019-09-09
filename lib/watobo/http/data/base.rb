module Watobo#:nodoc: all
  module HTTPData
    class Base
      def to_s
        s = @root.body.nil? ? "" : @root.body
      end

      def parameters2
        []
      end

      def has_parm2?
        false
      end

      def clear
        @root.set_body ''
      end

      def set2(p)
        false
      end

      def initialize(root)
        @root = root
      end
    end
  end
end
