# @private 
module Watobo#:nodoc: all
  module Gui
    
    def self.load_gui_icon(name)
      return nil if @icon_path.nil?
      icon = load_icon(File.join(@icon_path, name)) 
    end
    
    def self.load_icon(filename)
      begin
        icon = nil
        return icon if @application.nil?
        #filename = 
        File.open(filename, "rb") do |f| 
          if filename.strip =~ /\.ico$/ then
            icon = FXICOIcon.new(@application, f.read)
            #icon = FXICOIcon.new(getApp(), f.read)
          elsif filename.strip =~ /\.png$/ then
            icon = FXPNGIcon.new(@application, f.read)
          elsif filename.strip =~ /\.gif$/ then
            icon = FXGIFIcon.new(@application, f.read)
          end
          icon.create
        end
        
        icon
      rescue => bang
        puts "Couldn't load icon: #{filename}"
        puts bang
      end
      
    end
  end
end