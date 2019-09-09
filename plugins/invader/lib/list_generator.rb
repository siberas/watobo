require_relative './generator'
module Watobo
  module Plugin
    class Invader
      class SimpleListGenerator < Generator

        def run(prefs, &block)
          raise ":list key missing" unless prefs.has_key?(:list)

          prefs[:list].each do |e|
            yield [ e, e ] if block_given?
          end

        end

        def initialize()

          super 'Simple List'

        end
      end
    end
  end
end
