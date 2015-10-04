%w( client_socket http_socket ).each do |lib|
  require "watobo/sockets/#{lib}"
end

