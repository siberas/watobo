# @private 
module Watobo#:nodoc: all
  module Utils
    def loadIcon(app, filename)
      begin
        icon = nil
        
        File.open(filename, "rb") do |f| 
          if filename.strip =~ /\.ico$/ then
            icon = FXICOIcon.new(app, f.read)
            #icon = FXICOIcon.new(getApp(), f.read)
          elsif filename.strip =~ /\.png$/ then
            icon = FXPNGIcon.new(app, f.read)
          elsif filename.strip =~ /\.gif$/ then
            icon = FXGIFIcon.new(app, f.read)
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
