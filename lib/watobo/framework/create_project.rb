# @private 
module Watobo#:nodoc: all
  @project_name = ''
  @session_name = ''
  @project = nil
  
  def self.project_name
    @project_name
  end 
  
  def self.session_name
    @session_name
  end
 
  def self.project
    @project
  end

  def self.dev_mode
    @project = 'dev'
  end

  # create_project is a wrapper function to create a new project
  # you can either create a project by giving a URL (:url),
  # or by giving a :project_name AND a :session_name
  def self.create_project(prefs={})
    project_settings = Hash.new
    # project_settings.update @settings

    if prefs.has_key? :url
      #TODO: create project_settings from url
      else
      project_settings[:project_name] = prefs[:project_name]
      project_settings[:session_name] = prefs[:session_name]
    end

    Watobo::DataStore.connect(project_settings[:project_name], project_settings[:session_name])
    @project_name = project_settings[:project_name]
    @session_name = project_settings[:session_name]

    # updating settings
    Watobo::Conf.load_project_settings()
    Watobo::Conf.load_session_settings()

    # apply settings to modules/objects
    Watobo::Scope.set Watobo::Conf::Scope.to_h

    #project_settings[:session_store] = ds

    puts "* INIT PASSIVE MODULES"
    Watobo::PassiveModules.init
    puts
    puts "Total: " + Watobo::PassiveModules.length.to_s
   # project_settings[:passive_checks] = init_passive_modules
    #puts "Total: " + project_settings[:passive_checks].length.to_s
    #puts
    puts "* INIT ACTIVE MODULES"
    #project_settings[:active_checks] = init_active_modules
    Watobo::ActiveModules.init
    #  project_settings[:active_checks].each do |ac|
    #    puts ac.class
    #  end
    puts
    puts "Total: " + Watobo::ActiveModules.length.to_s
    puts

    project = Project.new(project_settings)
    #@running_projects << project
    @project = project

  end

end