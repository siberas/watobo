%w( init init_modules create_project license_text load_chat ).each do |lib|
  require File.join( "watobo", "framework", lib)
end


