module Watobo
  module Redis
    class Queue

      # Function to push an item to the queue
      def push(item)
        @rc.lpush(queue_name, item)
      end

      # Function to pop an item from the queue
      def pop(queue_name)
        @rc.rpop(queue_name)
      end

      def initialize(connection, name)
        @queue = name
        @rc = connection

      end

    end
  end
end