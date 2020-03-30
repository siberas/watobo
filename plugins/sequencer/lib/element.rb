module Watobo
  module Plugin
    class Sequencer
      class Element
        attr :name
        attr_writer :request, :pre_script, :post_script

        def run

        end

        def initialize(prefs)
          %w( name request pre_script post_script ).each do |e|
            instance_variable_set("@#{e}", prefs[e.to_sym])
          end
        end
      end
    end
  end
end