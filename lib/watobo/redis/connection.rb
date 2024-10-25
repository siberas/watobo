module Watobo
  module Redis
    class Connection
      def alive?
        begin
          redis.ping
        rescue Redis::BaseError => e
          return false
          # e.inspect
          # => #<Redis::CannotConnectError: Timed out connecting to Redis on 10.0.1.1:6380>

          # e.message
          # => Timed out connecting to Redis on 10.0.1.1:6380
        end
        return true
      end
    end
  end
end