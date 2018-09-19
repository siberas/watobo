# @private
module Watobo #:nodoc: all
  module Utils
    # returns false if response are different
    def self.compare_responses(one, two)
      # compare return code
      #puts "[status] #{one.status} - #{two.status}"
      return false if one.status != two.status
      # compare http header count
      return false if one.headers.length != two.headers.length
      # compare body length
      # body is rated different if length differs by at least 10%
      return false if (one.body.length - two.body.length).abs > (one.body.length / 10)

      true
    end
  end
end
