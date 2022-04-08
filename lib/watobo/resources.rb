Dir[File.join(__dir__, "resources/*.rb")].each do |file|
  require file
end