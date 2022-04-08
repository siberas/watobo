module Watobo
  module Scanner4


    class Scanner

      SCANNER_READY = 0x0000
      SCANNER_RUNNING = 0x0001
      SCANNER_FINISHED = 0x0002


      attr :status
      include Watobo::Subscriber

      def start(prefs={})
        @state = SCANNER_RUNNING
        num_workers = @prefs.has_key?(:max_parallel_checks) ? @prefs[:max_parallel_checks] : Watobo::Conf::Scanner.max_parallel_checks

        create_workers num_workers
        @generator_thread = start_generator

        Thread.new {
          while @generator_thread.status or @tasks.size > 0
            task = @tasks.deq
            print '.'
            binding.pry
            @channel.send task, move: true

          end
        }

      end
      alias :run :start


      def wait
        while running?
          sleep 1
        end
      end

      def finished?
        # TODO
      end

      def running?
        @state == SCANNER_RUNNING
      end



      def initialize(chat_list = [], active_checks = [], passive_checks = [], prefs = {})
        @prefs = Watobo::Conf::Scanner.to_h
        @prefs.update prefs

        @chat_list = chat_list

        @active_checks = setup_active_checks(active_checks, @prefs)

        @passive_checks = passive_checks.nil? ? [] : passive_checks

        @generator_thread = nil

        @tasks = Queue.new

        @task_counter = {}

        @state = SCANNER_READY

        # create a communication channel for generator and workers
        @channel = Ractor.new do
          loop do
            task = Ractor.receive
            Ractor.yield(task, move: true)
          end
        end
        @reciever = Ractor.new do
          loop do
            msg = Ractor.receive
            binding.pry
          end
        end

      end


      private

      def setup_active_checks(active_checks, prefs = {})
        unique_checks = {}
        active_checks.each do |x|
          if x.respond_to? :new
            ac = x.new(self.object_id, prefs)
          else
            ac = x
          end
          unique_checks[ac.class.to_s] = ac
        end

        unique_checks.values
      end

      def init_counter
        @active_checks.each do |check|

          check.resetCounters()
          @chat_list.each_with_index do |chat, index|
            #print "."
            check.updateCounters(chat, @prefs)
            puts "* [#{index + 1}] CheckCounter for Chat-ID #{chat.id}: #{check.check_name} - #{check.numChecks}"
          end

          # @numTotalChecks += check.numChecks
          # cn = check.info[:check_name]
          # puts "+ add check: #{cn}"
          # notify(:logger, LOG_INFO, "add check #{cn}")
          @task_counter[check.check_name] = {:total => check.numChecks,
                                             :progress => 0
          }
        end
      end


      def start_generator
        Thread.new {
        begin
          #set_status GENERATION_STARTED
          @chat_list.uniq.each do |chat|
            # puts chat.request.url.to_s
            @active_checks.uniq.each do |ac|
              ac.reset()
              if site_alive?(chat) then
                ac.generateChecks(chat) { |check|
                  while @tasks.size > 15
                    sleep 1
                  end
                  # TODO: make sleep configurable via "scanner settings"
                  #sleep 0.3
                  task = {:module => ac.check_name,
                          :check => check
                  }
                  @tasks.push task
                }
              end
            end
          end
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        ensure
          #set_status GENERATION_FINISHED
        end
      }
      end

      def site_alive?(chat)
        @sites_alive ||= Hash.new
        site = chat.request.site
        return true if @sites_alive.has_key? site

        if Watobo::HTTPSocket.siteAlive?(chat)
          @sites_alive[site] = true
          return true
        end
        return false
      end


      def create_workers(num_workers)
        num_workers.times.map do
          # we need to pass the channel and the engine so they are available
          # inside Ractor
          #binding.pry
          Ractor.new(@channel, @reciever, @prefs) do |channel, reciever, prefs|
            loop do
              # this method blocks until the channel yields a task
              puts "wait for task"
              task = channel.take
              puts "*"

              begin
                puts "RUNNING #{task[:module]}"
                request, response = task[:check].call()

                raise "no response" if response.nil?

                # TODO
                chat = Chat.new(request, response, :id => 0, :chat_source => prefs[:chat_source])
                reciever.notify(:new_chat, chat)


                if prefs.has_key?(:run_passive_checks)
                  Watobo::PassiveScanner.add(chat) if prefs[:run_passive_checks] == true
                end

                unless prefs[:scanlog_name].nil? or prefs[:scanlog_name].empty?
                  Watobo::DataStore.add_scan_log(chat, prefs[:scanlog_name])
                end
              rescue => bang
                puts "!!! #{task[:module]} !!!"
                puts bang
                puts bang.backtrace if $DEBUG
              ensure
                #puts "FINISHED #{task[:module]}"
                # Thread.current[:pos] = "scan_finished"
                reciever.notify(:task_finished, task[:module])
              end
                # Thread.exit if relogin_count > 5

            rescue => e
              puts e.message
            ensure
              # conn&.close
            end
          end
        end
      end

    end


  end
end