# @private
module Watobo #:nodoc: all
  module Utils
    # Evaluate a Ruby-string-literal read back from a saved file
    # (loadChatYAML / loadFindingYAML) so escape sequences round-trip
    # into raw bytes: `"POST /x HTTP/1.1\r\n"` -> the actual 20-byte
    # request line.
    #
    # The historical name was `secure_eval`; it wrapped `eval` in a
    # `$SAFE = 1` thread. `$SAFE` was frozen at 0 in Ruby 2.7 and removed
    # in 3.0, so the sandbox never applied on the currently supported
    # Ruby. The name was renamed to reflect what the function actually
    # does: eval a literal that we ourselves wrote to disk. Input is
    # trusted; if an attacker can rewrite files under ~/.watobo, they've
    # already won. Do not use this on any input that did not originate
    # in our own save code.
    def Utils.eval_saved_literal(exp)
      result = nil
      t = Thread.new(exp) do |e|
        begin
          result = eval(e)
        rescue SyntaxError, LocalJumpError => bang
          # Corrupted or truncated save file. Swallow so bulk loads
          # skip the bad entry instead of aborting.
          puts bang
          puts bang.backtrace if $DEBUG
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
      t.join
      result
    end
  end
end
