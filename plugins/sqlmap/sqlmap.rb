%w( sqlmap_ctrl ).each do |l|
  require_relative File.join("lib", l )
end