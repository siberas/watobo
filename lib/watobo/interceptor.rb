%w( proxy transparent ).each do |lib|
  require "watobo/interceptor/#{lib}"
end

