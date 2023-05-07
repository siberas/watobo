# @private 
module Watobo#:nodoc: all
  module Gui

    @@loaded_icons={}

    @icon_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", '..', '..', "icons"))


    def self.load_gui_icon(name)
      return nil if @icon_path.nil?
      icon = load_icon(File.join(@icon_path, name)) 
    end
    
    def self.load_icon(filename)
      begin
        icon = nil
        # return icon if @application.nil?
        raise "Need FXApp Instance before loading icons! (e.g. FXAPP.new)" unless FXApp.instance

        #return @@loaded_icons[filename] if @@loaded_icons.has_key?(filename)
        #filename = 
        File.open(filename, "rb") do |f| 
          if filename.strip =~ /\.ico$/ then
            #icon = FXICOIcon.new(@application, f.read)
            icon = FXICOIcon.new(FXApp.instance, f.read)
          elsif filename.strip =~ /\.png$/ then
            icon = FXPNGIcon.new(FXApp.instance, f.read)
          elsif filename.strip =~ /\.gif$/ then
            icon = FXGIFIcon.new(FXApp.instance, f.read)
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