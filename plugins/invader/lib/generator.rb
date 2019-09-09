module Watobo
  module Plugin
    class Invader

      class GeneratorFactory
        @@generators ||= []

        def self.each(&block)
          @@generators.each do |gen|
            # clazz = Kernel.const_get(gen)
            #clazz = Watobo.class_eval(gen)
            #binding.pry

            yield gen.new if block_given?
          end
        end

        def self.add(gen)
          puts "+ new generator: #{gen}" if $VERBOSE
          @@generators << gen
        end

      end

      class Generator
        attr :weight # used for sorting
        attr :name

        @@current = nil

        def self.inherited(subclass)
          GeneratorFactory.add subclass
        end


        def self.run(prefs, tweaks, &block)
          @@current.run(prefs) do |source, payload|
            if tweaks.empty?
              yield [ source, payload ] if block_given?
            else
              tweaks.each do |tweak|
                payload = tweak.func.call(payload)
              end
              yield [ source, payload ] if block_given?
            end
          end
        end


        def self.set(generator)
          @@current = generator
        end


        def initialize(name)
          @name = name
        end

        def run(prefs, &block)
          raise "No run-block set for generator #{self}"

        end
      end
    end
  end

end
