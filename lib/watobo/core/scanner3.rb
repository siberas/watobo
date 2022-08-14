# @private
module Watobo #:nodoc: all
  class Scanner3

    include Watobo::Constants
    include Watobo::Subscriber

    SCANNER_READY = 0x0000
    SCANNER_RUNNING = 0x0001
    SCANNER_FINISHED = 0x0002

    GENERATION_STARTED = 0x0100
    GENERATION_FINISHED = 0x0200


    class Worker
      include Watobo::Constants
      include Watobo::Subscriber

      attr :engine

      STATE_IDLE = 0x00
      STATE_RUNNING = 0x01
      STATE_WAIT_FOR_LOGIN = 0x02

      def state
        state = nil
        @state_mutex.synchronize do
          state = @state
        end
        state
      end

      def run
        @state_mutex.synchronize do
          @state = STATE_RUNNING;
        end
        Thread.new { @engine.run }
      end

      def start
        @engine = Thread.new(@prefs) { |prefs|
          relogin_count = 0
          loop do
            Thread.current[:pos] = "wait for task"

            # pulls new task from queue, waits if no task is available
            task = @tasks.deq
            begin
              puts "RUNNING #{task[:module]}" if $DEBUG
              request, response = task[:check].call()

              next if response.nil?

              unless prefs[:logout_signatures].empty? or prefs[:auto_login] == false
                logged_out = false
                prefs[:logout_signatures].each do |sig|
                  logged_out = true if response.join =~ /#{sig}/
                end

                if logged_out
                  Thread.current[:pos] = "logged out"
                  @state_mutex.synchronize do
                    @state = STATE_WAIT_FOR_LOGIN;
                  end
                  @logged_out_queue.push self
                  # stop current thread, will be waked-up by scanner
                  Thread.stop
                  relogin_count += 1
                  Thread.current[:pos] = "set state"
                  @state_mutex.synchronize do
                    @state = STATE_RUNNING;
                  end
                  unless relogin_count > 5
                    request, response = task[:check].call()
                  end
                end
              end

              # TODO
              chat = Chat.new(request, response, :id => 0, :chat_source => prefs[:chat_source])
              notify(:new_chat, chat)


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
              Thread.current[:pos] = "scan_finished"
              notify(:task_finished, task[:module])
            end
            if relogin_count > 5
              puts "Maximum Relogin Count reached ... giving up :("
              Thread.exit
            end
            relogin_count = 0
          end
        }
      end

      def stop
        @state_mutex.synchronize { @state = STATE_IDLE }
        begin
          return false if @engine.nil?
          if @engine.alive?
            puts "[#{self}] got stopped" if $DEBUG
            Thread.kill @engine
          end
          @engine = nil
        rescue => bang
          puts "!!! could not stop worker !!!"
          puts bang
          puts bang.backtrace
        end
      end

      def wait_for_login?
        state = false
        @state_mutex.synchronize do
          state = (@state == STATE_WAIT_FOR_LOGIN)
        end
        state
      end

      def running?
        @state_mutex.synchronize do
          running = (@state == STATE_RUNNING)
        end
        running
      end

      def initialize(task_queue, logged_out_queue, prefs)

        @engine = nil
        @tasks = task_queue
        @logged_out_queue = logged_out_queue
        @prefs = {}.update prefs
        @relogin_count = 0
        @state_mutex = Mutex.new
        @state = STATE_IDLE

      end

    end
    #
    #  E N D   O F   W O R K E R

    def tasks
      @tasks
    end

    def status_running?
      (status & SCANNER_RUNNING) > 0
    end

    def generation_finished?
      (status & GENERATION_FINISHED) > 0
    end

    def finished?

      status == SCANNER_FINISHED

    end

    def running?()
      status == SCANNER_RUNNING
    end

    def stop()
      print "\n[#{self}] stopping ... "
      begin
        @workers.each do |w|
          w.stop
        end
        unless @ctrl_thread.nil?
          if @ctrl_thread.alive?
            puts "stop ctrl_thread"
            Thread.kill @ctrl_thread
          end
        end
        set_status SCANNER_FINISHED
        print "[OK]\n"
      rescue => bang
        print "[OUTCH]\n"
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    alias :cancel :stop

    def progress
      @task_count_lock.synchronize do
        YAML.load(YAML.dump(@task_counter))
      end
    end

    def sum_total
      sum = 0
      @task_count_lock.synchronize do
        sum = @task_counter.values.inject(0) { |i, v| i + v[:total] }
      end
      sum
    end

    def sum_progress
      sum = 0
      @task_count_lock.synchronize do
        sum = @task_counter.values.inject(0) { |i, v| i + v[:progress] }
      end
      sum
    end

    def run(check_prefs = {})
      # @sites_online.clear
      @uniqueRequests = Hash.new
      set_status_running

      @login_count = 0
      @max_login_count = 20


      @prefs.update check_prefs
      msg = "\n[Scanner] Starting Scan ..."

      notify(:logger, LOG_INFO, msg)
      puts msg
      puts @prefs.to_yaml if $VERBOSE

      # starting workers before check generation
      start_workers(@prefs)
      @max_tasks = 1000

      # start check generation in seperate thread
      # TIMING of request is controlled here via limitation of the generation thread
      #
      Thread.new {
        begin
          set_status GENERATION_STARTED
          @chat_list.uniq.each do |chat|
            # puts chat.request.url.to_s
            @active_checks.uniq.each do |ac|
              ac.reset()
              if site_alive?(chat) then
                puts "Generating Tasks for #{ac}"
                ac.generateChecks(chat) { |check|
                  while @tasks.size > @max_tasks
                    sleep 1
                  end
                  # TODO: make sleep configurable via "scanner settings"
                  #sleep 0.3
                  task = {:module => ac,
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
          set_status GENERATION_FINISHED
        end
      }

      ctrl_thread

    end

    # possible prefs
    #   :evasions_enabled => TrueFalse, if true evasions module is enabled for checks

    def initialize(chat_list = [], active_checks = [], passive_checks = [], prefs = {})
      @chat_list = chat_list
      @active_checks = []
      @passive_checks = passive_checks.nil? ? [] : passive_checks

      @tasks = Queue.new
      @logged_out = Queue.new

      @workers = []

      @status_lock = Mutex.new

      @task_count_lock = Mutex.new
      @new_chat_notify = Mutex.new
      @task_counter = {}

      @ctrl_thread = nil

      # @onlineCheck = OnlineCheck.new(@project)
      msg = "Initializing Scanner ..."
      notify(:logger, LOG_INFO, msg)
      puts msg

      @prefs = Watobo::Conf::Scanner.to_h

      @prefs.update prefs
      @prefs[:timeout] = 5 unless !!@prefs[:timeout]

      #puts @prefs.to_yaml

      unique_checks = {}
      active_checks.each do |x|
        if x.respond_to? :new
          ac = x.new(self.object_id, @prefs)
        else
          ac = x
        end
        unique_checks[ac.class.to_s] = ac unless unique_checks.has_key?(ac.class.to_s)
      end
      unique_checks.each_value do |check|
        @active_checks << check
      end

      puts "# Num Active Modules: #{@active_checks.length}"

      @active_checks.uniq.each do |check|

        # enable evasion module if available and active
        # TODO: also set evasion_filter
        if check.respond_to? :enable_evasion
          !!@prefs[:evasions_enabled] ? check.enable_evasion : check.disable_evasion
        end

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
      @status = SCANNER_READY
      msg = "Scanner Ready!"
      notify(:logger, LOG_INFO, msg)
      puts msg
    end

    private

    def ctrl_thread
      @ctrl_thread = Thread.new {
        size = -1
        loop do
          if @tasks.num_waiting == @workers.length and @tasks.size == 0 and generation_finished?
            begin
              puts "[#{self}] seems scan is finished. stopping workers now ..."
              @workers.map { |w|
                #puts "[]#{self}] stopping worker #{w}"
                w.stop
              }

              notify(:state_changed, SCANNER_FINISHED)
              notify(:scanner_finished)
              @status = SCANNER_FINISHED
              # suizide!
              Thread.exit
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end

          if @logged_out.size == (@workers.length - @tasks.num_waiting) or @tasks.num_waiting == @workers.size
            @logged_out.clear
            #puts "!LOGOUT DETECTED!\n#{@logged_out.size} - #{@workers.length} - #{@tasks.num_waiting}\n\n"
            begin
              puts "Run login ..."
              login
              @workers.each do |wrkr|
                # puts "State: #{wrkr.state}"
                if wrkr.wait_for_login?
                  wrkr.engine.run
                end
              end

            rescue => bang
              puts bang
              puts bang.backtrace
            end

          end

          sleep 1
        end
      }
    end

    def set_status_running
      s = (status | SCANNER_RUNNING)
      set_status(s)
    end

    def set_status(s)
      @status_lock.synchronize {
        @status |= s
      }
    end

    def status
      @status_lock.synchronize {
        return @status
      }
    end

    def start_workers(check_prefs)
      num_workers = @prefs.has_key?(:max_parallel_checks) ? @prefs[:max_parallel_checks] : Watobo::Conf::Scanner.max_parallel_checks

      puts "Starting #{num_workers} Workers ..." if $VERBOSE

      num_workers.times do |i|
        puts "... #{i + 1}" if $VERBOSE
        w = Scanner3::Worker.new(@tasks, @logged_out, check_prefs)

        w.subscribe(:task_finished) { |m|
          @task_count_lock.synchronize do
            cn = m.check_name
            @task_counter[cn][:progress] += 1
          end
        }

        w.subscribe(:new_chat) { |c|
          @new_chat_notify.synchronize do
            notify(:new_chat, c)
          end
        }

        @logout_count ||= 0
        @logout_count_lock ||= Mutex.new
        @num_waiting = 0

        w.start
        @workers << w
      end

    end

    def login
      #puts "do relogin"
      unless Watobo::Conf::Scanner.login_chat_ids.nil?
        login_chats = Watobo::Conf::Scanner.login_chat_ids.uniq.map { |id| Watobo::Chats.get_by_id(id) }
        #  puts "running #{login_chats.length} login requests"
        #  puts login_chats.first.class

        @active_checks.first.runLogin(login_chats, @prefs)
      end

    end

    def site_alive?(chat)
      @sites_alive ||= Hash.new
      site = chat.request.site
      if @sites_alive.has_key? site
        return @sites_alive[site]
      end

      if Watobo::HTTPSocket.siteAlive?(chat)
        @sites_alive[site] = true
      else
        @sites_alive[site] = false
      end

      return @sites_alive[site]
    end

  end
end
