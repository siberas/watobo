# @private
module Watobo#:nodoc: all
  module Plugin
    class CQ5
      class Dispatcher
        
        def stop
          @t_disp.kill unless @t_disp.nil?
        end
        
        def run
          @known_urls = []
          puts Watobo::Plugin::CQ5.ignore_patterns
          @t_disp = Thread.new{
            loop do
               new_item = @dqueue.deq
               unless @known_urls.include?( new_item[:url] )
                 @known_urls << new_item[:url]
                 if Watobo::Plugin::CQ5.ignore_patterns.empty?
                  # puts "* no ignore patterns defined"
                   @wqueue << new_item
                 elsif Watobo::Plugin::CQ5.ignore_patterns.select{|ip| new_item[:url] =~ /#{ip}/i }.empty?
                   @wqueue << new_item 
                 end
                 
                 @rqueue << new_item
               else
                 puts "[DUPLICATED] >> #{new_item[:url]}"
               end
              
             end
          }
        end
        
        def initialize(disp_queue, work_queue, result_queue)
          @dqueue = disp_queue
          @wqueue = work_queue
          @rqueue = result_queue
          @t_disp = nil
        end
      end
    end
  end
end