# @private 
module Watobo #:nodoc: all
  class PluginBase
    def self.inherited(subclass)
      %w( plugin_name plugin_path description version author output_path config_path lib_path ).each do |cvar|
        define_method(cvar) {self.class.instance_variable_get("@#{cvar}")}
        define_singleton_method("get_#{cvar}") {
          return nil unless instance_variable_defined?("@#{cvar}")
          instance_variable_get("@#{cvar}")
        }
        define_singleton_method("#{cvar}") {|val| instance_variable_set("@#{cvar}", val)}
      end
      path = File.join(File.dirname(caller[0]))
      subclass.plugin_path path if File.exist?(path)
      lpath = File.join(path, "lib")
      subclass.lib_path lpath if File.exist?(lpath)
    end

    def self.load_libs(*order)
      lpath = get_lib_path
      if order.empty?
        libs = Dir.glob("#{lpath}/*.rb")
      else
        libs = order.map {|l| l.to_s + ".rb"}
      end

      libs.each do |lib|
        puts "Loading library file: #{lib}" if $VERBOSE
        load File.join(lib)
      end
    end

    def self.gui
      @gui
    end


    def self.create_gui()
      if self.const_defined? :Gui
        gui = self.class_eval("Gui")
        @gui = gui.new()
        return @gui
      end
      puts "No GUI available for #{self}!"
      raise "No GUI available for #{self}!"
      #return nil

    end

    def self.load_gui(*order)
      # load if WATOBO is in GUI mode
      if Watobo.const_defined? :Gui
        # gui_path = File.join(File.dirname(caller[0]), "gui")
        gui_path = File.join(get_plugin_path, "gui")
        # TODO: change load ordering as follows
        # 1. load all libs defined in load definition
        # 2. load ALL other libs
        if order.empty?
          libs = Dir.glob("#{gui_path}/*")
        else
          libs = order.map {|l| File.join(gui_path, l.to_s + ".rb")}
        end

        begin

          main = libs.select {|l| l =~ /main.rb/i}

          load main.first
       #   binding.pry
          libs.each do |lib|

            puts "loading gui-lib #{lib} ..." if $VERBOSE

            load lib

          end
        rescue => bang
          puts bang
          puts bang.backtrace
            #binding.pry
        end
      else
        puts "WATOBO NOT IN GUI MODE!"
      end
    end

    def self.has_gui?
      puts self
      return true
    end


  end

  class PluginGui < FXDialogBox

    include Watobo::Gui
    include Watobo::Gui::Icons

    extend Watobo::Subscriber


    def self.inherited(subclass)
      %w( icon_file icons_path window_title width height config_path ).each do |cvar|
        define_method(cvar) {self.class.instance_variable_get("@#{cvar}")}
        define_singleton_method("get_#{cvar}") {
          return nil unless instance_variable_defined?("@#{cvar}")
          instance_variable_get("@#{cvar}")
        }
        define_singleton_method("#{cvar}") {|val| instance_variable_set("@#{cvar}", val)}
      end

      base_class = class_eval(subclass.to_s.gsub(/::Gui/, ''))
      plugin_path = base_class.get_plugin_path
      ipath = File.join(plugin_path, "icons")
      if File.exist?(ipath)
        # define_singleton_method("icons_path"){ "#{ipath}" }
        subclass.icons_path ipath
      end

    end

    def updateView()
      raise "!!! updateView not defined"
    end

    # tells GUI if plugin can handle single chats, e.g. a reciever for "send to"-menue
    def is_chat_reciever?
      @chat_reciever
    end

    def initialize(opts = {})
      # _width = instance_variable_get("@width")
      # puts _width
      # puts _width.class
      copts = {:opts => DECOR_ALL, :width => 800, :height => 600}
      copts.update opts
      title = self.class.instance_variable_defined?("@window_title") ? window_title : "#{self}"
      super(Watobo::Gui.application, title, copts)

      # make configuration settings available
      #extend Watobo::Config

      @chat_reciever = false
      @update_timer = nil


      @timer_lock = Mutex.new
      load_icon

    end

    private


    def load_icon
      ipath = icons_path
      ifile = icon_file

      #binding.pry
      return false if ipath.nil? or ifile.nil?

      myicon = File.join(ipath, ifile)
      puts "* loading icon > #{myicon}" if $VERBOSE
      if File.exist? myicon
        #puts "* loading icon > #{myicon}"
        picon = Watobo::Gui.load_icon(myicon)
        setIcon picon if getIcon.nil?
        setMiniIcon picon if getIcon.nil?
      end
    end

    def update_timer(ms = 250, &block)
      FXApp.instance.removeTimeout(@update_timer) unless @update_timer.nil?
      @update_timer = FXApp.instance.addTimeout(ms, :repeat => true) {
        @timer_lock.synchronize do
          if block_given?
            block.call if block.respond_to? :call
          end
        end
      }
    end

    def remove_timer
      FXApp.instance.removeTimeout(@update_timer) unless @update_timer.nil?
      @update_timer = nil
    end

  end
end

