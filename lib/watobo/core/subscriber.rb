# @private 
module Watobo#:nodoc: all

  module Subscriber

    def subscribe(event, &callback)
      @event_dispatcher_listeners ||= Hash.new
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def clearEvents(event)
      @event_dispatcher_listeners ||= Hash.new
      @event_dispatcher_listeners[event] ||= []
      @event_dispatcher_listeners[event].clear
    end

    def notify(event, *args)
      @event_dispatcher_listeners ||= Hash.new
      if @event_dispatcher_listeners[event]
       # puts "NOTIFY: #{self}(:#{event}) [#{@event_dispatcher_listeners[event].length}]" if $DEBUG
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

  end
end