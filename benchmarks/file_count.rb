require 'rake'
require 'benchmark'

#source_path = '//server/share/**/*.csv'
source_path = ARGV[0] ? ARGV[0] : '/tmp/**/*'

Benchmark.bm do |x|
  x.report("FileList  ") { puts FileList.new(source_path).size }
  x.report("Dir.glob  ") { puts Dir.glob(source_path).length }
  x.report("Dir[]     ") { puts Dir[source_path].length }
end