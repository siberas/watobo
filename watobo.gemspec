inc_path = File.expand_path(File.join(File.dirname(__FILE__), "lib"))
$: << inc_path

require 'watobo'

watobo_version = Watobo::VERSION
raise 'no version defined' unless watobo_version =~ /^\d/
  
spec = Gem::Specification.new do |s|
  s.name = 'watobo'
  s.version = watobo_version
  s.licenses = ['GPL-2.0']
  s.summary = 'WATOBO - Web Application Toolbox'
  s.description ="WATOBO is intended to enable security professionals to perform efficient (semi-automated ) web application security audits. It works like a local web proxy."
  s.homepage = "http://watobo.sourceforge.net"
  s.email = "watobo@siberas.de"
  s.require_paths = ['lib']
  s.executables = [ 'watobo_gui.rb', 'watobo', 'nfq_server.rb' ]
  s.authors = 'Andreas Schmidt'

  s.required_ruby_version     = '>= 2.2.2'
  s.required_rubygems_version = '>= 1.8.11'

  s.add_dependency 'mechanize', '2.7.4'
  s.add_dependency 'fxruby', '1.6.29'
  s.add_dependency 'jwt', '1.5.4'
  s.add_dependency 'bundler', '>= 1.11.0', '< 2.0'

  files = []

  excludes = [ "plugins/soaper", "plugins/scrambler", "plugins/sqlinjector", "modules/active/RoR"]

  %w( extras lib config certificates modules plugins icons custom-views ).each do |path|
    Dir.glob("#{path}/**/*").each do |f|
      next unless excludes.select{ |e| f =~ /#{e}/i }.empty?
      files << f
    end
  end

  %w( README.md CHANGELOG.md .yardopts).each do |fn|
     files << fn if File.exist?(fn)
  end

  s.files = files
end
