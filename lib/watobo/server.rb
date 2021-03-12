require_relative './server/server'

def require_plugin(dir_name)
  Dir["#{File.dirname(__FILE__)}/../../plugins/#{dir_name.to_s}/lib/*.rb"].sort.each do |f|
    puts "+ loading #{f} ..." if $VERBOSE
    require f
  end
end


# load headless-ready plugins
hrps = %w( filescanner crawler )

hrps.each do |hrp|
  require_plugin hrp
end