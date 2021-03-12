module Watobo
  module Plugin
    class Sequencer
      class Element

        include Watobo::Mixins::RequestParser


        attr :name
        attr_accessor :request, :pre_script, :post_script, :enabled, :egress_handler

        # we need this for RequestParser mixin
        def to_s
          @request
        end

        def to_h
          h = {}
          h[:name] = @name
          h[:request] = @request
          h[:pre_script] = @pre_script
          h[:post_script] = @post_script
          h[:enabled] = @enabled
          h[:egress_handler] = @egress_handler
          h
        end

        def enabled?
          @enabled
        end

        def enable
          @enabled = true
        end

        def disable
          @enabled = false
        end

        def initialize(prefs)
          @request = nil
          @pre_script = nil
          @post_script = nil
          @egress_handler = nil
          @enabled = true
          %w( name request pre_script post_script enable egress_handler).each do |e|
            instance_variable_set("@#{e}", prefs[e.to_sym])
          end
        end
      end
    end
  end
end