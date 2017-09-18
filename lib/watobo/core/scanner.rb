# @private 
module Watobo#:nodoc: all
  class Scanner2

    attr :numTotalChecks
    attr :numChecksPerModule
    attr :progress

    include Watobo::Constants
    
    def subscribe(event, &callback)
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def clearEvents(event)
      @event_dispatcher_listener[event].clear
    end

    def notify(event, *args)
      if @event_dispatcher_listeners[event]
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

    def running?()
      return true if @status == :running
      return false
    end

    def stop(reason="undef")
      begin
        notify(:scanner_stopped, reason)
        @status = :stopped
        puts "* stopping #{@check_list.length} active checks"
        @check_list.each do |check|
          check.stop
        end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    def cancel(reason="undef")
      begin
        notify(:scanner_canceled, reason)
        #  puts "* cancel active checks" unless @check_list.empty?
        @status = :canceled
        @check_list.each do |check|
          check.kill
        end
        #@active_checks.each do |mod|
        #  mod.cancel()
        #end
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    def siteAlive?(chat)
      #puts chat.class
      site = nil
      host = nil
      port = nil

      site = chat.request.site

      return @sites_online[site] if @sites_online.has_key?(site)

      if @prefs[:proxy].is_a? Hash
        Watobo.print_debug("Using Proxy","#{@prefs[:proxy].to_yaml}") if $DEBUG
        if @prefs[:proxy].has_key?(:name) and @prefs[:proxy].has_key?(:port)
          #  unless @prefs[:proxy][:name] == '' then
          puts "* testing proxy:"
          puts "#{@prefs[:proxy][:name]} (#{@prefs[:proxy][:host]}:#{@prefs[:proxy][:port]})"
          # print "* using forwarding proxy #{@project.settings[:proxy]}\r\n"
          use_proxy = true
          host = @prefs[:proxy][:host]
          port = @prefs[:proxy][:port]
        end
      else
        print "* check if site is alive (#{site}) ... "
      host = chat.request.host
      port = chat.request.port

      end

      return false if host.nil? or port.nil?

      begin
        tcp_socket = nil
        #  timeout(6) do

        tcp_socket = TCPSocket.new( host, port)
        tcp_socket.setsockopt( Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, 1)
        tcp_socket.sync = true

        socket = tcp_socket

        if socket.class.to_s =~ /SSLSocket/
        socket.io.shutdown(2)
        else
        socket.shutdown(2)
        end
        socket.close
        print "[OK]\n"
        @sites_online[site] = true
        return true
      rescue Errno::ECONNREFUSED
        p "* connection refused (#{host}:#{port})"
      rescue Errno::ECONNRESET
        puts "* connection reset"
      rescue Errno::EHOSTUNREACH
        p "* host unreachable (#{host}:#{port})"

      rescue Timeout::Error
        p "* TimeOut (#{host}:#{port})\n"

      rescue Errno::ETIMEDOUT
        p "* TimeOut (#{host}:#{port})"

      rescue Errno::ENOTCONN
        puts "!!!ENOTCONN"
      rescue OpenSSL::SSL::SSLError
        p "* ssl error"
        socket = nil
        #  puts "!!! SSL-Error"
        print "E"
      rescue => bang
      #  puts host
      #  puts port
        puts bang
        puts bang.backtrace if $DEBUG
      end
      print "[FALSE]\n"
      @sites_online[site] = false
      return false
    #        if @sites_online.has_key?(site) then
    #          return @sites_online[site] ? true : false
    #        end

    #        if @onlineCheck.isOnline?(chat) then
    #          puts "Site #{site} is online"
    #          @sites_online[site] = true
    #          return true
    #        else
    #    puts "Site #{site} is offline"
    #          @sites_online[site] = false
    #          return false
    #        end
    end

    def continue()
      puts "!!! Scan Running !!!"
      @active_checks.each do |mod|
        mod.run()
      end
      @status_running = true
    end

    def run( check_prefs={} )
      @status_running = true
      @sites_online.clear
      @uniqueRequests = Hash.new
      @status = :running
      @check_list = []
      @login_count = 0
      @max_login_count = 20

      # counter for fired checks
      checks = 0
      puts "= run scan =" if $DEBUG
      puts check_prefs.to_yaml if $DEBUG
      msg = "\n[Scanner] Starting Scan ..."
      notify(:logger, LOG_INFO, msg )
      puts msg
      #scan_session = Time.now.to_i

      @active_checks.uniq.each do |mod|
        check = mod
        #check = mod.new(@prefs[:scan_session], @prefs ) if mod.respond_to? :new
        puts "* subscribe for logout" if $DEBUG
        check.subscribe(:logout) { |m|
          next if @login_count > @max_login_count or @prefs[:auto_login] == false
          if @login_mutex.try_lock
            begin
              m.waitLogin(true)
              Watobo.print_debug("LOGOUT DETECTED") if $DEBUG
              @login_count += 1
              m.runLogin(@prefs[:login_chats])

              m.waitLogin(false) if m
            rescue => bang
              Watobo.print_debug("Could not relogin") if $DEBUG
              puts bang
              puts bang.backtrace if $DEBUG
            ensure

            end
          @login_mutex.unlock
          end

        }

        puts "* subscribe for :check_finished" if $DEBUG
        check.clearEvents(:check_finished)

        check.subscribe(:check_finished) do |m, request, response|
        # update progress
          @check_count ||= 0
          @check_count += 1
          puts "CheckCount: #{@check_count}" if $DEBUG
          notify( :progress, m )
          unless @prefs[:scanlog_name].nil?            
              chat = Chat.new(request, response, :id => 0, :chat_source => @prefs[:chat_source])
              Watobo::DataStore.add_scan_log(chat, @prefs[:scanlog_name])            
          end
        end

        puts "* subscribe for :new_finding" if $DEBUG
        check.clearEvents(:new_finding)
        check.subscribe(:new_finding) do |f|
        #    p "* NEW FINDING"
        #   p f.details[:module]
          notify(:new_finding, f)
        end

      end

      tlist = []
      @filtered_chat_list.uniq.each do |chat|
       # puts "CHAT --> #{chat.id}"
        @active_checks.uniq.each do |mod|
        #  puts "MOD"
          print "---> #{mod.class}"
          # accept Class- and Check-Types
          check = mod

          # reset check counters and variables
          check.reset()
          if @prefs[:online_check] == false or siteAlive?(chat) then
            @check_list << Thread.new(check, chat, check_prefs){|m, c, p|
              begin
              m_name = m.class.to_s.gsub(/.*::/,'')
              notify(:module_started, m_name)
              m.run_checks(c,p)
              rescue => bang
                puts bang
                puts bang.backtrace
              end
              notify(:logger, LOG_INFO, "finished checks: #{m.class} on chat #{c.id}")
              notify(:module_finished, m)
            }
          end
        end
      end

      @check_list.each {|ct| ct.join }
      puts "*[#{self}] Scan Finished"
    end

    def initialize(chat_list=[], active_checks=[], passive_checks=[], prefs={})
      # @project = project        # needed for centralized session management

      @numTotalChecks = 0
      @numChecksPerModule = Hash.new
      @chat_list = chat_list
      @active_checks = active_checks
      @passive_checks = passive_checks

      @login_in_progress = false
      @login_mutex = Mutex.new
      @login_cv = ConditionVariable.new

      @filtered_chats = []

      #  @thread_list = Hash.new
      @scan_pool = []
      @scan_pool_mutex = Mutex.new
      @scan_pool_cv = ConditionVariable.new

      @check_list = []

      @sites_online = Hash.new
      @event_dispatcher_listeners = Hash.new
      @status = :stopped

      # @onlineCheck = OnlineCheck.new(@project)
      msg = "Initializing Scanner ..."
      notify(:logger, LOG_INFO, msg)
      puts msg

      @prefs = {
        #:root_path => [],
        #:excluded_chats => [],
        :smart_scan => true,
        :excluded_parms => [],
        #:non_uniq_parms => [],
        :login_chat_ids => [],
        :auto_login => true,
        # :valid_sids => Hash.new,
        :sid_patterns => [],
        :run_passive_checks => false,
        :proxy => '',
        :scanlog_dir => '',
        :scan_session => Digest::MD5.hexdigest(Time.now.to_f.to_s),
        :check_online => true,
        :source => CHAT_SOURCE_UNDEF
      }

      @prefs.update prefs
      #puts "set up scanner"
      #puts @prefs[:login_chats]
      #puts @prefs[:logout_signatures]
      puts "= create scanner =" if $DEBUG
      puts @prefs.to_yaml if $DEBUG

      @filtered_chat_list = filteredChats(@chat_list, @prefs)
      puts "#ActiveModules: #{@active_checks.length}"

      @active_checks.uniq.each do |m|
        puts m.class
        check = m
        check = m.new(:dummy) if check.respond_to? :new
        check.resetCounters()
        # puts "* updating counters for module #{m.info[:check_name]}"
        #  puts "* updating #{@chat_list.length} chats"
        @filtered_chat_list.each do |chat|
          print "."
          check.updateCounters(chat, @prefs)
          puts "* [#{chat.id}] CheckCounter: #{check.info[:check_name]} - #{check.numChecks}" if $DEBUG
        end

        @numTotalChecks += check.numChecks
        cn = check.info[:check_name]
        # puts "+ add check: #{cn}"
        notify(:logger, LOG_INFO, "add check #{cn}")
        @numChecksPerModule[cn] = check.numChecks
      end
      msg = "Scanner Ready!"
      notify(:logger, LOG_INFO, msg)
      puts msg
    end

    private

    # Function: filteredChats
    # It's primarily used to reduce the number of requests for the scan.
    # Returns [] of chats which fulfill the requirements.
    # Inputs:
    # - chats: list of chats[]
    # - prefs: :non_unique_parms=>[], :smart_scan=>true|false
    def filteredChats(chats, prefs = {})
      check_ids = Hash.new
      fchats = []
      hstring = ''
      if prefs[:smart_scan] == true then
        chats.each do |chat|
          ps = chat.request.parm_names.sort
          if prefs[:non_unique_parms] and prefs[:non_unique_parms].length > 0 then
            ps.map!{|p|
              if prefs[:non_unique_parms].include?(p) then
              p += chat.request.get_parm_value(p)
              end
            }
          end

          next if chat.request.site.nil?
          hstring = chat.request.site + chat.request.path + chat.request.file + ps.join
          rhash = Digest::MD5.hexdigest(hstring)

          next if check_ids.has_key?(rhash)
          # p hstring
          check_ids[rhash] = nil
          fchats.push chat
        end
      else
      fchats = chats
      end
      return fchats
    end
  end
end
