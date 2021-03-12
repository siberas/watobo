# @private 
module Watobo #:nodoc: all
  class Plugin2 < FXDialogBox
    attr :plugin_name
    # attr :icon

    include Watobo::Gui
    include Watobo::Gui::Icons

    @icon_file = nil

    def self.get_icon_file
      @icon_file
    end

    def self.icon_file(icon_file)
      # puts "Caller >> #{caller.class}"
      # puts caller.to_yaml

      dummy = caller.first.split(":")
      dummy.pop
      file = dummy.join(":")

      @icon_file = File.expand_path(File.join(File.dirname(file), "..", "icons", icon_file))
    end

    def load_icon
      icon_file = self.class.get_icon_file

      puts "[Plugin2] loading icon: #{icon_file}" if $VERBOSE
      # icon = Watobo::Gui.load_icon(icon_file) unless icon_file.nil? didn't work???
      picon = icon_file.nil? ? nil : Watobo::Gui.load_icon(icon_file)
      #  puts picon.class
      setIcon picon
      setMiniIcon picon
    end

    def subscribe(event, &callback)
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def clearEvents(event)
      @event_dispatcher_listener[event].clear
    end

    def notify(event, *args)
      if @event_dispatcher_listeners[event]
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

    def updateView()
      raise "!!! updateView not defined"
    end

    def logger(msg)
      t = Time.now
      now = t.strftime("%m/%d/%Y @ %H:%M:%S")

      @update_lock.synchronize do
        text = "\n#{now}: msg"
        @log_messages << text
      end
    end

    def initialize(owner, title, project, opts)
      copts = { :opts => DECOR_ALL, :width => 800, :height => 600 }
      copts.update opts
      super(owner, title, copts )

      @icon = nil
      @update_timer = nil
      load_icon()
      @plugin_name = "undefined"
      @event_dispatcher_listeners = Hash.new
      @update_lock = Mutex.new

      @log_messages = []

      add_update_timer()

    end

    private

    def on_update_timer

    end

    def add_update_timer(ms=250)
      @update_timer = FXApp.instance.addTimeout(ms, :repeat => true){
            #@update_lock.synchronize do
              on_update_timer()
            #end
      }
    end

    def remove_update_timer
      #app = FXApp.instance
      app = getApp
      if app.hasTimeout? @update_timer
        app.removeTimeout @update_timer
      end
    end

  end
end
