require_relative 'crawler.rb'

%w( crawler_gui settings_tabbook general_settings_frame status_frame hooks_frame auth_frame scope_frame ).each do |l|
 #puts "Loading >> #{l}"
  require_relative File.join("gui", l)
end
