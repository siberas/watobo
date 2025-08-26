module Watobo
  module Utils
    def self.explode_path(path)
      parts = path.split('/').reject(&:empty?)
      result = ['/']

      parts.each_with_index do |_, i|
        result << '/' + parts[0..i].join('/') + '/'
      end

      result
    end
  end
end