Dir["#{File.expand_path(File.dirname(__FILE__))}/lib/*.rb"].sort.each do |f|
  require f
end
