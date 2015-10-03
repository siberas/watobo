# @private 
module Watobo#:nodoc: all
  module Gui
    @plugin_list = []
    def self.add_plugin(p)
      @plugin_list << p
    end

    def self.plugins
      @plugin_list
    end

    def self.clear_plugins
      @plugin_list = []
    end

    module Utils
      def self.load_plugins(project=nil)
        raise ArgumentError, "Need a project" unless project
        # this is the old plugin style
        Dir["#{Watobo.plugin_path}/*"].each do |sub|
          if File.ftype(sub) == "directory"
            pgf = File.join(sub, "gui.rb")
            if File.exist? pgf
              puts "Loading Plugin GUI #{pgf} ..."

              group = File.basename(sub)
              plugin = File.basename(pgf).sub(/\.rb/,'')
              # load "#{@settings[:module_path]}/#{modules}/#{check}"
              group_class = group.slice(0..0).upcase + group.slice(1..-1).downcase
              #
              plugin_class = plugin.slice(0..0).upcase + plugin.slice(1..-1).downcase
              class_name = "Watobo::Plugin::#{group_class}::#{plugin_class}"
              puts
              puts ">> ClassName: #{class_name}"
              puts
              load pgf
              class_constant = Watobo.class_eval(class_name)

              Watobo::Gui.application.runOnUiThread do
                Watobo::Gui.add_plugin class_constant.new(Watobo::Gui.application, project)
              end
            else

              Dir["#{sub}/#{File.basename(sub)}.rb"].each do |plugin_file|
                begin
                  puts "* processing plugin file #{plugin_file}" if $DEBUG
                  load plugin_file
                  group = File.basename(sub)
                  plugin = File.basename(plugin_file).sub(/\.rb/,'')
                  # load "#{@settings[:module_path]}/#{modules}/#{check}"
                  group_class = group.slice(0..0).upcase + group.slice(1..-1).downcase
                  #
                  plugin_class = plugin.slice(0..0).upcase + plugin.slice(1..-1).downcase
                  class_constant = Watobo.class_eval("Watobo::Plugin::#{group_class}::#{plugin_class}")

                  Watobo::Gui.add_plugin class_constant.new(Watobo::Gui.application, project)
                rescue => bang
                  puts bang if $DEBUG
                  puts bang.backtrace if $DEBUG
                #   notify(:logger, LOG_INFO, "problems loading plugin: #{plugin_file}")
                end
              end

              # this the way loading new plugins

              Dir["#{sub}/gui/#{File.basename(sub)}.rb"].each do |plugin_file|
                begin
                  puts "* processing plugin file #{plugin_file}" if $DEBUG
                  load plugin_file
                  group = File.basename(sub)
                  plugin = File.basename(plugin_file).sub(/\.rb/,'')
                  # load "#{@settings[:module_path]}/#{modules}/#{check}"
                  group_class = group.slice(0..0).upcase + group.slice(1..-1).downcase
                  #
                  plugin_class = plugin.slice(0..0).upcase + plugin.slice(1..-1).downcase
                  class_name = "Watobo::Plugin::#{group_class}::Gui::Main"
                  #puts class_name
                  class_constant = Watobo.class_eval(class_name)

                  Watobo::Gui.application.runOnUiThread do
                    Watobo::Gui.add_plugin class_constant.new(Watobo::Gui.application, project)
                  end
                rescue => bang
                  puts bang
                  puts bang.backtrace if $DEBUG
                #   notify(:logger, LOG_INFO, "problems loading plugin: #{plugin_file}")
                end
              end
              #

              Watobo::Plugin.constants.each do |pc|
                puts ">> PLUGIN >> #{pc.to_s}"

                pclass = Watobo::Plugin.class_eval(pc.to_s)

                if pclass.respond_to? :create_gui
                  puts "ADD NEW PLUGIN #{pc.upcase}"
                  # TODO: In later versions - if all plugins are switched to the new style - this will not be necessary here
                  Watobo::Gui.application.runOnUiThread do
                    gui = pclass.create_gui()
                    # puts gui.class
                    Watobo::Gui.add_plugin pclass
                  end

                # exit
                end
              end
            end
          end
        end

      end
    #-------------
    end
  end
end