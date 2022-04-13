module Watobo
  module Utils

    def self.merge_paths(base, target, &block)
      merged = []
      base_dirs = base.split('/')
      target_dirs = target.split('/')
      # if base does not start with '/' iterations will not work because first element of base is not empty
      # so we might have to manually add this
      base_dirs.unshift('') unless base_dirs.first.strip.empty?

      base_dirs.length.times do |bi|
        target_dirs.length.times do |ti|
          merge = File.join(base_dirs[0..bi].join('/'), target_dirs[ti * (-1)..-1])
          next if merged.include? merge
          yield merge if block_given?
          merged << merge
        end
      end

      merged
    end
  end
end

if $0 == __FILE__
  base = ARGV[0] ? ARGV[0] :'/my/path/to'
  target = ARGV[1] ? ARGV[1] : '/cqa/var'

  puts "= Merge Paths ="
  puts "Base: #{base}"
  puts "Target: #{target}"
  Watobo::Utils.merge_paths(base, target) do |path|
    puts path
  end
end