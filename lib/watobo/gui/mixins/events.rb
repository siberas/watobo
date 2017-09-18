# @private
module Watobo #:nodoc: all
  module Gui
    module Events_UNUSED

      def self.extended(base)
        base.instance_variable_set('@event_dispatcher_listeners', {})
      end

      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listeners[event] ||= []
        @event_dispatcher_listeners[event].clear
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end
    end
  end
end
