%w( data_store session_store ).each do |lib|
  require "watobo/adapters/#{lib}"
end

#require "watobo/adapters/file/file_store"
require "watobo/adapters/file/marshal_store"
