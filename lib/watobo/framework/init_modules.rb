# @private
module Watobo#:nodoc: all

  private
  def self.init_passive_modules_UNUSED(filter='')
    # puts "get passive modules from path #{@settings[:module_path]}/passive"
    passive_modules = []
    passive_path = Watobo.passive_module_path

    Dir["#{passive_path}/*.rb"].each do |mod_file|
      begin
        mod = File.basename(mod_file)

        require mod_file
        #  puts "+ #{modules}"
        # load "#{@settings[:module_path]}/#{modules}/#{check}"
        classname = mod.slice(0..0).upcase + mod.slice(1..-1).downcase
        classname.sub!(".rb","")

        # How to get a class constant out of a string ??? Here we go ...

        class_constant = Watobo::Modules::Passive.const_get(classname)

        # passive_modules.push class_constant.new(self)
        passive_modules.push class_constant
        #  puts "+ #{classname}"
        #  notify(:logger, LOG_DEBUG, "#{modules} loaded.")

      rescue => bang
        puts "!!!"
        puts bang
      end
    end
    passive_modules
  end

  def self.init_passive_modules(filter='')
    # puts "get passive modules from path #{@settings[:module_path]}/passive"
    passive_modules = []
    
    Dir["#{Watobo.passive_module_path}/*.rb"].each do |mod_file|
      begin
        mod = File.basename(mod_file)

        load mod_file
      rescue => bang
        puts "!!!"
        puts bang
      end
    end

    Watobo::Modules::Passive.constants.each do |m|
      begin
        class_constant = Watobo::Modules::Passive.const_get(m)
        passive_modules.push class_constant
      rescue => bang
        puts "!!!"
        puts bang
      end
    end
    passive_modules
  end

  def self.init_active_modules()

    active_path = Watobo.active_module_path
    Dir["#{active_path}/**"].each do |group|
      if File.ftype(group) == "directory"
        Dir["#{group}/*.rb"].each do |mod_file|
          begin
          #           module_file = File.join(active_path, group, modules)
            mod = File.basename(mod_file)
            group_name = File.basename(group)# notify(:logger, LOG_DEBUG, "loading module: #{module_file}")
            #require "#{active_path}/#{group}/#{modules}"
            require mod_file
            # load "#{@settings[:module_path]}/#{modules}/#{check}"
            group_class = group_name.slice(0..0).upcase + group_name.slice(1..-1).downcase
            #
            module_class = mod.slice(0..0).upcase + mod.slice(1..-1).downcase
            module_class.sub!(".rb","")
            # How to get a class constant out of a string ??? Here we go ...

            #  class_constant = Watobo.class_eval("Watobo::Modules::Active::#{group_class}::#{module_class}")
            class_constant = Watobo::Modules::Active.const_get(group_class).const_get(module_class)
            #@active_checks.push class_constant.new(self)
            # notify(:logger, LOG_INFO, "#{module_class} loaded.")
            active_checks.push class_constant
          rescue => bang
            puts '---'
            puts bang
            puts "when loading module file #{mod_file}"
            puts '---'
          # notify(:logger, LOG_DEBUG, "problems loading module: #{@settings[:module_path]}/active/#{group}/#{modules}")
          end
        end
      end

    end
    active_checks
  end

  def self.createModule(filename)
    begin
    #@interface.log("loading module: /active/#{group}/#{modules}")
    #require "#{@settings[:module_path]}/active/#{group}/#{modules}"
    #require "#{module_path}/#{group}/#{modules}"
      require filename
      # load "#{@settings[:module_path]}/#{modules}/#{check}"
      group_class = group.slice(0..0).upcase + group.slice(1..-1).downcase
      #
      module_class = modules.slice(0..0).upcase + modules.slice(1..-1).downcase
      module_class.sub!(".rb","")
      # How to get a class constant out of a string ??? Here we go ...

      class_constant = Watobo.class_eval("Watobo::Modules::Active::#{module_class}")

      @active_modules.push class_constant.new(self)
      #@interface.log("#{modules} loaded.")

    rescue => bang
      puts bang
      #@interface.log("problems loading module: #{module_path}/#{group}/#{modules}")
      puts "problems loading module: #{filename}"
    end
  end
end
