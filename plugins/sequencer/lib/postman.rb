module Watobo
  module Plugin
    class Sequencer
      class PostmanCollection
        attr :collection

        def initialize(file)
          @collection = JSON.parse(File.read(file))
        end

        def to_elements

        end


        def is_collection?(item)
          item['item'].class == Array
        end

        def is_request?(item)
          !item['request'].nil?
        end

      end


      class PostmanEnvironment

        def initialize(file)
          @environmant = JSON.parse(File.read(file))
        end
      end
    end
  end

end

if __FILE__ == $0
  fcol = ARGV[0]
  puts "+ reading file #{fcol}"

  pc = Watobo::Plugin::Sequencer::PostmanCollection.new fcol

end