inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'swagger'

input = ARGV[0]
files = [input]
if File.directory?(input)
  # files = Dir.glob("#{input}/*.(yaml|json)")
  files = Dir.glob("#{input}/*.json")
  files.concat Dir.glob("#{input}/*.yaml")
end

paths = []
files.each do |f|
  puts 'Processing: ' + f
  begin
    api = Swagger.load f
    api.operations.each do |o|
      url = URI.parse "http://#{o.signature.gsub(/^.* /, '').gsub(/[\{\}]/, '')}"
      paths << url.path
    end
  rescue => bang
    puts bang
  end
end

puts paths