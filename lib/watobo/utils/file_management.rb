# @private 
module Watobo#:nodoc: all
  module Utils
    # e.g, save_settings("test-settings.test", 0, "@saved_settings", @saved_settings) 
    
    def Utils.save_settings(file, settings)
      begin
        if settings.is_a? Hash
          File.open(file, "w") { |fh|
            YAML.dump(settings, fh)
          }
          return true
        else
          return false
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return false
    end
    
    def Utils.load_settings(file)
      settings = nil
      if File.exists?(file) then
        settings = YAML.load_file(file)
      end
      return settings
    end 
    
    def Utils.saveChat(chat, filename)
      return false if filename.nil?
      return false if chat.nil?
      chat_data = {
        :request => chat.request.map{|x| x.inspect},
        :response => chat.response.map{|x| x.inspect},
      }
      
      chat_data.update(chat.settings)  
                    
      if File.exists?(filename) then
        puts "Updating #{filename}"
        File.open(filename, "w") { |fh| 
          YAML.dump(chat_data, fh)
        }
        chat.file = filename
      end
    end
    
  end
end
