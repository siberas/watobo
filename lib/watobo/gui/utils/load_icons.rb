# @private 
module Watobo#:nodoc: all
  module Gui

    @@loaded_icons={}
    def self.load_gui_icon(name)
      return nil if @icon_path.nil?
      icon = load_icon(File.join(@icon_path, name)) 
    end
    
    def self.load_icon(filename)
      begin
        icon = nil
        return icon if @application.nil?
        #return @@loaded_icons[filename] if @@loaded_icons.has_key?(filename)
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
          @@loaded_icons[filename] = icon
        end
        
        return icon
      rescue => bang
        puts "Couldn't load icon: #{filename}"
        puts bang
      end
      return nil
    end
  end
end