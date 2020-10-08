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
      body_one_length = one.has_body? ? one.body.length : 0
      body_two_length = two.has_body? ? two.body.length : 0
      unless body_one_length == body_two_length
        small_body = body_one_length > body_two_length ? body_two_length : body_one_length
        return false if (body_one_length - body_two_length).abs > (small_body / 10)
      end
      true
    end
  end
end
