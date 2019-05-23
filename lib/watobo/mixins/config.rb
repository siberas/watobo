module Watobo

  class ConfigClazz < OpenStruct

    # Filename of default location
    # @return [String]
    def filename
      stack = ( @owner.is_a?(Class) ? @owner.to_s : @owner.class.to_s ).split('::')
      clazz_name = stack.pop
      grp_name = stack.pop

      subdir = grp_name.nil? ? '' : Watobo::Utils.snakecase(grp_name)

      cname = Watobo::Utils.snakecase(clazz_name)

      wd = Watobo.working_directory

      conf_dir = File.join(wd, 'conf')
      Dir.mkdir conf_dir unless File.exist? conf_dir

      grp_dir = File.join(conf_dir, subdir)
      Dir.mkdir grp_dir unless File.exist? grp_dir

      File.join(grp_dir, cname + '_settings.yml')
    end

    # checks if default configuration files exists
    # @return [Bool]
    def exist?
      File.exist? filename
    end

    def to_s
      s = []
      each_pair do |k, v|
        s << "#{k}: #{v}"
      end
      s.join("\n")
    end

    # clear/resets the current configuration
    def clear
      marshal_load({})
    end

    # Loads values from configuration file
    # the content should be a yaml file with symbol keys. Strings as key don't work because of OpenStruct.marshal_load
    # functionality.
    # @param file [String] filename, if none is given the default location will be used
    # @param block [Block] yields to block for whatever
    # @return [Bool]
    def load(file = nil, &block)
      cfg_file = file.nil? ? filename : file
      return false unless File.exist?(cfg_file)

      cfg = YAML.load_file(cfg_file)

      puts "* loading configuration for #{@owner} (#{@owner.class}) ... " if $DEBUG

      marshal_load(cfg)

      true
    end


    # Saves the current configuration
    # @param file [String] alternative filename
    # @param block [Block] yields dup of current config. can be altered for storing, e.g. remove sensitive
    # information. Running config will not be touched.
    def save(file = nil, &block)
      cfg_file = file.nil? ? filename : file
      puts 'saving ...' if $DEBUG
      cfg = self.dup
      cfg = yield cfg if block_given?
      File.open(filename, 'w') {|fh| fh.puts YAML.dump(self.to_h)}
      true
    end

    def initialize(owner)
      @owner = owner
      super()
    end
  end


  module Config

    def self.included(base)
      base.instance_variable_set('@config', ConfigClazz.new(base))
      base.send :define_singleton_method, :config do
        instance_variable_get('@config')
      end
    end


    def self.extended(base)
      base.instance_variable_set('@config', ConfigClazz.new(base))
      base.send :define_singleton_method, :config do
        instance_variable_get('@config')
      end
    end

  end


end