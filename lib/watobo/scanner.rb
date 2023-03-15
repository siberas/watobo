Dir[File.join(__dir__, "scanner/*.rb")].each do |file|
  require file
end