# @private 
module Watobo#:nodoc: all
  module Utils
    # expand range creates an array out of 
    def self.expand_range(pattern)
      vals = pattern.split(",")

      result = []
      vals.each do |v|
        v.strip!
        if v =~ /^(\d+)$/ then
          result.push $1.to_i
        elsif v =~ /^(\d+)-(\d+)$/
          start = $1
          stop = $2
          dummy = (start..stop).to_a
          result.concat dummy
        end
      end
      result.uniq!
      return result
    end

  end
end