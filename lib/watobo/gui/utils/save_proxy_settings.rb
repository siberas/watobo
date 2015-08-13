# @private 
module Watobo#:nodoc: all
  def self.save_proxy_settings(prefs={})
    
    puts "* save proxy settings"

    c_prefs = {
      :save_passwords => false,
      :key => ""
    }

    c_prefs.update prefs

    unless Watobo.project.nil?
      Watobo::Conf::ForwardingProxy.save_project() do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    else

      Watobo::Conf::ForwardingProxy.save do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    end

  end
  
  def self.save_proxy_settings_UNUSED(prefs={})
    
    puts "* save proxy settings"

    c_prefs = {
      :save_passwords => false,
      :key => ""
    }

    c_prefs.update prefs

    unless Watobo.project.nil?
      Watobo::Conf::ForwardingProxy.save_project() do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    else

      Watobo::Conf::ForwardingProxy.save do |s|
        s.each do |name, proxy|
          next unless proxy.is_a? Hash
          unless c_prefs[:save_passwords] == false
            unless c_prefs[:key].empty?
            #asdfa
            end
          else
            proxy[:password] = ''
          end
        end
      end
    end

  end

end