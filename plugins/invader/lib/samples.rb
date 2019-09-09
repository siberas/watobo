module Watobo
  module Plugin
    class Invader

      class SampleSet
        attr :name

        def add(source, chat)
          @samples << OpenStruct.new( :source => source, :chat => chat )
        end

        def initialize(name)
          @name = name
          @samples = []
        end

        def method_missing(name, *args, &block)
          super unless @samples.respond_to?(name)
          @samples.send(name, *args, &block)
        end
      end

    end
  end
end
