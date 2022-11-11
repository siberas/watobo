module Watobo
  module Headless
    class Spider
      class Stat
        attr :resource, :duration

        def initialize(resource, duration)
          @resource = resource
          @duration = duration
        end
      end
    end
  end
end
