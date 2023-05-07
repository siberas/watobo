module Watobo
  module Scanner
    class HostupCheck



      # @param inputs [Array] of Watobo::Chats or URIs
      def get_alive_sites(inputs)
        unique_origins = inputs.map{|c|
          ( c.respond_to?(:request) ? c.request.origin : c.origin )
        }.uniq
        check_queue = Queue.new
        result_queue = Queue.new

        results = []
        workers = []
        num_workers = [unique_origins.length, @max_workers].min
        num_workers.times do
          workers << Thread.new(check_queue, result_queue){|input, results|
            loop do
              origin = input.deq
              begin
                req = Watobo::Request.new(origin)

                sender = Watobo::Net::Http::Sender.new @prefs
                request, response = sender.exec req
                puts response.status_code
                results << case response.status_code
                           when /^(555|502|504)/
                             nil
                           else
                             origin
                           end
              rescue => bang
                puts bang
                puts bang.backtrace
                results << nil
                raise bang
              end

            end
          }
        end

        unique_origins.map{|o| check_queue << o }

        while results.length < unique_origins.length
          results << result_queue.deq
        end

        binding.pry
        results.compact
      end

      def initialize(prefs)
        @prefs = prefs
        @max_workers =  @prefs[:max_parallel_checks] || 10
      end

    end
  end
end