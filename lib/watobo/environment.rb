module Watobo #:nodoc: all #:nodoc: all

  VERSION = "1.1.0pre"

  # base directory aka installation path
  def self.base_directory
    @base_directory ||= ""
    @base_directory = File.expand_path(File.join(File.dirname(__FILE__), "..", ".."))
  end

  def self.plugin_path
    @plugin_directory ||= ""
    @plugin_directory = File.join(base_directory, "plugins")
  end

  # initialize and return the path where the active modules resides
  def self.active_module_paths
    return @active_module_paths if @active_module_paths
    default_path = File.join(base_directory, "modules", "active")
    @active_module_paths = [ default_path ]

    if ENV['WATOBO_MODULES']
      ENV['WATOBO_MODULES'].split(':').each do |path|
        if File.exist? path
          @active_module_paths << path
        else
          puts "Module path #{path} does not exist!"
        end
      end
    end

    @active_module_paths
  end

  def self.passive_module_path
    @passive_module_path = ""
    @passive_path = File.join(base_directory, "modules", "passive")
  end

  def self.version
    Watobo::VERSION
  end


end