# @private 
module Watobo#:nodoc: all
  module Plugin
    class Sqlmap
      @well_known_paths = [
        "/pentest/database/sqlmap/", # BackTrack
        "/usr/share/sqlmap/"         # Kali Linux, Samurai WTF
      ]
      @binary_path = ''
      @command = ""
      @tmp_dir = nil
      # set sqlmap binary path, leave it empty to check well-know-locaitons
      # it returns the path if any or an empty string
      def self.set_binary_path(path=nil)
        search_paths = @well_known_paths
        search_paths = [ path ] unless path.nil?
        @binary_path = ""
        
        [ "sqlmap.py",
          "sqlmap"     # on some distributions no .py extension, e.g. kali linux
        ].each do |binary_name|
          search_paths.each do |p|
            bp = File.join(p, binary_name)
            if File.exist? bp
              @binary_path = bp
              break
            end
          end
        end
        save_config

        @binary_path
      end

      def self.method_missing(name, *args, &block)
        iv_name = "@#{name}"
        super unless instance_variable_defined? iv_name

        v = instance_variable_get(iv_name)
      end

      def self.set_tmp_dir(dir=nil)
        # get project path
        if dir.nil?
          @tmp_dir = File.join(Watobo.temp_directory,"sqlmap")
          Dir.mkdir @tmp_dir unless File.exist? @tmp_dir
        else
          @tmp_dir = dir if File.exist? dir
        end
        save_config
        @tmp_dir
      end

      def self.run(request, opts)

      end

      def self.save_config()
        wd = Watobo.working_directory

        dir_name = Watobo::Utils.snakecase self.name.gsub(/.*::/,'')
        path = File.join(wd, "conf", "plugins")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_config.yml")
        config = { 
                   :tmp_dir => @tmp_dir,
                   :binary_path => @binary_path
                   }
        Watobo::Utils.save_settings(file, config)
      end

      def self.load_config()
        wd = Watobo.working_directory
        dir_name = Watobo::Utils.snakecase self.name.gsub(/.*::/,'')
        path = File.join(wd, "conf", "plugins")
        Dir.mkdir path unless File.exist? path
        conf_dir = File.join(path, dir_name)
        Dir.mkdir conf_dir unless File.exist? conf_dir
        file = File.join(conf_dir, dir_name + "_config.yml")
        config = Watobo::Utils.load_settings(file)
      end

      # set default values
      config = load_config
      puts config.class
      unless config.nil?
        set_binary_path config[:binary_path]
        set_tmp_dir config[:tmp_dir]
      else
        set_binary_path
        set_tmp_dir
      end

    end
  end
end