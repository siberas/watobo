# @private
module Watobo #:nodoc: all
  module Plugin
    class Sequencer
      class Gui

        class VarFrame < FXVerticalFrame

          include Watobo::Subscriber

          def element=(e)

          end

          def initialize(owner, opts)
            frame_opts = {}
            frame_opts[:opts] = opts
            super(owner, frame_opts)
          end
        end
      end
    end
  end
end
