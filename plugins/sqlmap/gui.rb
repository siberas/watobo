require_relative 'sqlmap'

%w( main options_frame ).each do |l|
  require_relative File.join('gui', l )
end
