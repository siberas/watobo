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
      if File.exist?(file) then
        settings = YAML.load_file(file)
      end
      return settings
    end

    def Utils.saveChat(chat, filename)
      return false if filename.nil?
      return false if chat.nil?

      Watobo::DataStore.save_chat(filename, chat)
    end

    
  end
end
