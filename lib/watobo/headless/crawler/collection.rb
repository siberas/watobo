module Watobo
  module Headless
    class Spider
      class Collection < Array

        def fingerprint
          raise "needs to be defined"
        end

        def initialize()
          super
        end

      end
    end
  end
end