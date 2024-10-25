inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
$: << inc_path

require 'openapi3_parser'
require 'yaml'
require 'pry'

input = ARGV[0]
files = [input]
if File.directory?(input)
  # files = Dir.glob("#{input}/*.(yaml|json)")
  files = Dir.glob("#{input}/*.json")
  files.concat Dir.glob("#{input}/*.yaml")
end

def remove_keys(obj, keys)
  case obj
  when Hash
    obj.reject { |k, _| keys.include?(k) }
       .transform_values { |v| remove_keys(v, keys) }
  when Array
    obj.map { |v| remove_keys(v, keys) }
  else
    obj
  end
end

def clean_description(d)
  c = d.gsub(/<[^<]{,10}>/,' ')
  c = c.gsub(/\s+/,' ')
  c
end

def fix_required_fields(openapi)
  unless openapi['info']
    openapi['info'] = { "title" => "OpenAPI"}
  end
  unless openapi['info']['version']
    openapi['info']['version'] = "1.0.0"
  end
end

bad_keys = %w( exampleSetFlag type types extensions nullable )
files.each do |f|

  begin
    if f.match?(/\.json$/i)
      data = JSON.parse(IO.read(f))
    else
      data = YAML.load_file(f)
    end
    data = remove_keys(data, bad_keys)
    fix_required_fields(data)
    api = Openapi3Parser.load data
    puts "---------------------"
    puts "#{File.basename(f)};#{api.info.title};#{api.info.description}"

    api.paths.keys.each do |k|

      begin
        puts "#{k};;#{api.paths[k].description}"
        methods = %w( post get put delete options head patch trace )
        allowed_methods = []
        descriptions = []
        methods.each do |m|
          next if api.paths[k].send(m).nil?
          descr = api.paths[k].send(m).description
          if descr && descr.length > 100
            i = descr.index(' ', 100)
            blank_index = i.nil? ? 100 : i
            descr = clean_description(descr[0..blank_index]) + ' ...'
          end
          puts ";#{m};#{descr}"

        end


      rescue => bang
        puts "!!!"
        binding.pry
      end
      # binding.pry
    end
  rescue => bang
    # puts bang
    binding.pry
  end
end

