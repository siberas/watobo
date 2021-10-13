# @private 
module Watobo #:nodoc: all

  @active_checks = []
  @passive_checks = []
  @running_projects = []

  @tmp_dir = ""

  def self.running_projects
    @running_projects
  end

  def self.active_checks
    @active_checks
  end

  def self.passive_checks
    @passive_checks
  end

  def self.init_framework()
    init_working_directory

    Watobo::Conf.each do |cm|
      # puts "\n=== #{cm.group_name} ==="
      # puts cm.to_h.to_yaml
      cm.update
      # puts "#"
      # puts cm.to_h.to_yaml
    end

    init_workspace_path
    init_active_modules
    init_passive_modules
  end

  def self.temp_directory
    @tmp_dir
  end

  def self.working_directory
    # puts "Method Obsolet! use Watobo::Conf::General.working_directory instead."
    Watobo::Conf::General.working_directory
  end

  def self.workspace_path=(new_wsp)
    # puts "Method Obsolet! use Watobo::Conf::General.workspace_path instead."
    Watobo::Conf::General.workspace_path = new_wsp
  end

  def self.workspace_path
    Watobo::Conf::General.workspace_path
  end

  private

  def self.init_workspace_path
    # gs = @settings[:general]
    if Conf::General.respond_to? :working_directory
      unless Conf::General.respond_to? :workspace_path
        if File.exist? Conf::General.working_directory
          dir = ''
          dir = Conf::General.workspace_name if Conf::General.respond_to? :workspace_name
          wsp = File.join(Conf::General.working_directory, dir)
          unless File.exist? wsp
            Dir.mkdir(wsp)
            puts "* created workspace folder #{wsp}"
          end
          Conf::General.workspace_path = wsp
        else
          puts "! working directory #{Conf::General.working_directory} does not exist."
          exit
        end
      else
        unless File.exist? Conf::General.workspace_path
          begin
            print "* Create Workspace Directory '#{Conf::General.workspace_path}' .."
            Dir.mkdir(Conf::General.workspace_path)
            print "OK\n"
          rescue => bang
            print "Autsch!\n"
            puts "!!! Could Not Create Workspace Directory"
            exit
          end
        end
      end
    else
      puts "! working directory not set."
      puts Conf::General.dump.to_yaml
      exit
    end
  end

  def self.init_working_directory()
    puts "* init_working_directory"
    puts working_directory

    watobo_folder = ".watobo"
    watobo_folder = Conf::General.watobo_folder if Conf::General.respond_to? :watobo_folder

    if ENV['WATOBO_HOME']
      Conf::General.working_directory = ENV['WATOBO_HOME']
    else
      unless Conf::General.respond_to? :working_directory
        case RUBY_PLATFORM

        when /mswin|mingw|bccwin/

          Conf::General.working_directory = File.join(ENV['HOME'], watobo_folder)

        when /linux|bsd|solaris|hpux|darwin/i

          Conf::General.working_directory = File.join(ENV['HOME'], watobo_folder)

        else # cygwin|java
          puts "!!! WATOBO is not tested for this platform (#{RUBY_PLATFORM})!!!"
          exit
        end
      end
    end
    unless File.exist? Conf::General.working_directory
      $first_time_watobo = true
      begin
        print "Creating WATOBO's working directory #{Conf::General.working_directory}."
        Dir.mkdir(Conf::General.working_directory)
      rescue => bang
        puts "Could not create working directory for WATOBO."
        puts bang
        puts bang.backtrace if $DEBUG
        exit
      end
    end

    if File.exist? Conf::General.working_directory
      cfg_dir = File.join(Conf::General.working_directory, "conf")
      unless File.exist? cfg_dir
        puts "* create configuration directory '#{cfg_dir}' ..."
        Dir.mkdir(cfg_dir)
        print "OK\n"
      end

      @tmp_dir = File.join(Conf::General.working_directory, "tmp")
      unless File.exist? @tmp_dir
        puts "* create temp directory '#{@tmp_dir}' ..."
        Dir.mkdir(@tmp_dir)
        print "OK\n"
      end
    end
  end
end