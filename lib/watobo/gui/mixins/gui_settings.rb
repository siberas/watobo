# @private 
module Watobo#:nodoc: all
  module Gui
    module Settings
       def self.save_gui_settings(settings)
        wd = Watobo.working_directory

        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "gui")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_settings.yml")
        
        Watobo::Utils.save_settings(file, config)
      end

      def load_gui_settings()
        wd = Watobo.working_directory
        dir_name = Watobo::Utils.snakecase self.class.to_s.gsub(/.*::/,'')
        path = File.join(wd, "conf", "gui")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_settings.yml")
        config = Watobo::Utils.load_settings(file)
        config
      end
    end
  end
end