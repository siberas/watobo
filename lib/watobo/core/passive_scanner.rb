# @private 
module Watobo #:nodoc: all
  module PassiveScanner
    @queue = Queue.new
    @max_threads = 1
    @scanners = []
    class Engine
      def initialize
        @t = nil
      end

      def run
        @t = Thread.new {
          loop do
            # we don't need a sleep here, because pop is blocking
            #if Watobo::PassiveScanner.queue.size > 0
              chat = Watobo::PassiveScanner.pop
              # TODO: make max size configurable
              unless chat.nil? or chat.response.to_s.length > 500000
                Watobo::PassiveModules.each do |test_module|
                  begin
                    test_module.do_test(chat)
                  rescue => bang
                    puts bang
                    puts bang.backtrace #if $DEBUG
                    #return false
                  end
                end
              end
              #else
              #sleep 0.5
            #end
          end
        }
      end
    end

    def self.queue
      @queue
    end

    def self.pop
      return @queue.pop
    end

    def self.start
     #@max_threads.times do |i|
        e = Engine.new
        e.run
     #end
    end

    def self.add(chat)
      @queue.push chat
    end

  end
end