# @private 
module Watobo#:nodoc: all
  def self.load_defaults
    config_path = File.expand_path(File.join(File.dirname(__FILE__),"..","..", "config"))
    #   puts "* loading defaults from #{config_path}"
    Dir.glob("#{config_path}/*.yml").each do |cf|
      dummy = File.basename(cf).gsub!(/.yml/,'')
      #cc = dummy.strip.gsub(/[^[a-zA-Z\-_]]/,"").gsub( "-" , "_").split("_").map{ |s| s.downcase.capitalize }.join
      cc = Watobo::Utils.camelcase dummy
      begin
        puts cf
        settings = YAML.load_file(cf)
        settings = {} if !settings

        Watobo::Conf.add(cc,  settings )
      rescue => bang
        puts "[#{self}] Could not load config #{cf}"
      end
    end
  end

end

#puts "=== loading defaults ==="
Watobo.load_defaults
