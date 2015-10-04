# @private 
module Watobo#:nodoc: all
  class ActiveModules
    @checks = []
    def self.each(&block)
      if block_given?
        @checks.map{|c| yield c }
      end

    end

    def self.to_a
      @checks
    end

    def self.length
      @checks.length
    end

    def self.init
      @checks = []
      active_path = Watobo.active_module_path
      Dir["#{active_path}/**"].each do |group|
        if File.ftype(group) == "directory"
          Dir["#{group}/*.rb"].each do |mod_file|
            begin
            #           module_file = File.join(active_path, group, modules)
              mod = File.basename(mod_file)
              group_name = File.basename(group)# notify(:logger, LOG_DEBUG, "loading module: #{module_file}")

              require mod_file

              group_class = group_name.slice(0..0).upcase + group_name.slice(1..-1).downcase
              #
              module_class = mod.slice(0..0).upcase + mod.slice(1..-1).downcase
              module_class.sub!(".rb","")

              ac = Watobo::Modules::Active.const_get(group_class).const_get(module_class)
              print "."
              
              @checks << ac
            rescue => bang
              puts bang
            end
          end
        end
      end
      @checks
    end
  end

end