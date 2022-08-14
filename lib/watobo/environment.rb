module Watobo #:nodoc: all #:nodoc: all

  VERSION = "1.1.0pre"

  # base directory aka installation path
  def self.base_directory
    @base_directory ||= ""
    @base_directory = File.expand_path(File.join(File.dirname(__FILE__), "..",".."))
  end

  def self.plugin_path
    @plugin_directory ||= ""
    @plugin_directory = File.join(base_directory, "plugins")
  end

  # initialize and return the path where the active modules resides
  def self.active_module_path
    return @active_module_path if @active_module_path
    default_path = File.join(base_directory, "modules", "active")
    @active_module_path = nil

    if ENV['WATOBO_MODULES']
      if File.exist? ENV['WATOBO_MODULES']
        @active_module_path = ENV['WATOBO_MODULES']
      else
        puts "Given module path does not exist! Using default #{default_path}"
      end
    end

    @active_module_path = default_path unless @active_module_path
  end

  def self.passive_module_path
    @passive_module_path = ""
    @passive_path = File.join(base_directory, "modules", "passive")
  end

  def self.version
    Watobo::VERSION
  end


end