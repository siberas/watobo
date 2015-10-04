# @private 
module Watobo#:nodoc: all
  class PassiveModules
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
          pc = class_constant.new(self)
          print "."
          @checks << pc

        rescue => bang
          puts "!!!"
          puts bang
        end
      end
      
      passive_modules
    end
  end
end