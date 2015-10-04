# @private 
module Watobo#:nodoc: all
  class ActiveCheck  < Watobo::Session    # Base Class for Passive Checks
    include Watobo::CheckInfoMixin

    attr :info
    attr :numChecks

    #   @@running_checks = 0
    @@max_checks = 5
    @@check_count = 0
    @@pool = []
    @@pool_mutex = Mutex.new
    @@pool_cv = ConditionVariable.new

    @@status = :running # :running, :paused, :canceled
    @@lock = Mutex.new
    
     @info = {
        :check_name => '',    # name of check which briefly describes functionality, will be used for tree and progress views
        :check_group => 'Misc',   # groupname of check, will be used to group checks, e.g. :Generic, SAP, :Enumeration
        :description => '',   # description of checkfunction
        :author => "not modified", # author of check
        :version => "unversioned",   # check version
        :target => nil               # reserved

      }

      @finding = {
        :title => 'untitled',          # [String] title name, used for finding tree
        :check_pattern => nil,         # [String] regex of vulnerability check if possible, will be used for highlighting
        :proof_pattern => nil,         # [String] regex of finding proof if possible, will be used for highlighting
        :threat => '',        # threat of vulnerability, e.g. loss of information
        :measure => '',       # measure
        :class => "undefined",# [String] vulnerability class, e.g. Stored XSS, SQL-Injection, ...
        :subclass => nil,     # reserved
        :type => FINDING_TYPE_UNDEFINED,         # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
        :chat => nil,         # related chat must be linked
        :rating=> VULN_RATING_UNDEFINED,  #
        :cvss => "n/a",       # CVSS Base Vector
        :icon => nil,     # Icon Type
        :timestamp => nil         # timestamp
      }
    
    def self.inherited(subclass)
        subclass.instance_variable_set("@info", YAML.load(YAML.dump(@info)))
        subclass.instance_variable_set("@finding", YAML.load(YAML.dump(@finding)))
    end
           
    def addFinding(request, response, details)
      @@lock.synchronize {

        t = Time.now
        now = t.strftime("%m/%d/%Y@%H:%M:%S")

        new_details = Hash.new
        finding_info = self.class.instance_variable_get("@finding")
        #puts finding_info.to_yaml
        new_details.update(finding_info)

        new_details.update(details)
        new_details[:tstamp] = now

        id_string = ''
        id_string << request.site
        id_string << request.path
        id_string << new_details[:test_item] if new_details[:test_item]
        id_string << new_details[:class] if new_details[:class]
        id_string << new_details[:title]  if new_details[:title]

        if id_string == '' then
        id_string = (Time.now.to_i + rand(10000)).to_s
        end
        #
        unless new_details.has_key? :fid
         new_details[:fid] = Digest::MD5.hexdigest(id_string)        
        end
       
        puts new_details[:fid] if $DEBUG

        new_details[:module] = self.class.to_s
        # new_details[:module] = Module.nesting[]

        new_details[:chat_id] = new_details[:chat].id
        new_details.delete(:chat)

        new_finding = Watobo::Finding.new(request, response, new_details)
      #  puts new_finding
        Watobo::Findings.add new_finding
       # notify(:new_finding, new_finding)
      }
    end

    def reset()
      # should be overridden, if counters or status information are used!!!
    end

    def resetCounters()
      @numChecks = 0
      @counters = Hash.new
      @progress = 0
      reset()
    end

    def updateCounters(chat, *prefs)
      @settings[:excluded_parms] = prefs[:excluded_parms] if prefs.is_a? Hash and prefs[:excluded_parms]
      c = getCheckCount(chat)
      @counters[chat.id] = c
      @numChecks += @counters[chat.id]

      puts "#{chat.id} : #{c}"
    end

    def urlParmNames(chat)
      begin
        pnames = chat.request.get_parm_names
        # puts @settings.to_yaml
        if @settings.has_key? :excluded_parms
          @settings[:excluded_parms].each do |p|
            pnames.delete(p)
          end
        end
      rescue => bang
      puts "! settings 'excluded_parms' missing !"
      #  puts @project.settings.to_yaml
      puts bang
      puts bang.backtrace if $DEBUG
      end
      return pnames
    end

    def postParmNames(chat)
      pnames = chat.request.post_parm_names
      return pnames unless @settings.has_key? :excluded_parms
      return pnames unless @settings[:excluded_parms].is_a? Array
      begin
      pnames.select!{|p| !@settings[:excluded_parms].include? p }        
      rescue => bang
      #puts "! settings 'excluded_parms' missing !"
      #  puts @project.settings.to_yaml
      puts bang
      puts bang.backtrace if $DEBUG
      end
      return pnames
    end

    def getCheckCount(chat)
      count = 0
      generateChecks(chat) do |check|
        count += 1 if check.respond_to? :call
      end
      count
    end

    def maxChecks=(m)
      @@max_checks = m
    end

    def maxChecks()
      @@max_checks
    end

    def enabled?
      @enabled
    end

    def enabled=(status)
      @enabled = status.is_a? TrueClass|FalseClass
    end

    def enable
      @enabled = true
    end

    def checksRunning?
      begin
        puts @inner_pool.size
        return true if @inner_pool.size > 0
        return false
      rescue => bang
      p bang
      p bang.backtrace
      end
    end

    def disable
      @enable = false
    end

    def generateChecks(chat)
      raise "Missing method generateChecks()!!!"
    end

    def waitLogin_UNUSED(state)
      @@login_in_progress = state
      @inner_pool_cv.signal if state == false
    end

    def continue_UNUSED()
      @@pool.each do |thr|
      #  puts "Stopping #{thr}"
        begin
          thr.run if not thr.run?
        rescue
        puts "could not continue thread #{thr}"
        end
      end
    end

    def cancel_UNUSED()
      @@status = :stopped
      @inner_pool.each do |thr|
        begin
          if thr.alive?
          puts "Stopping #{thr}" if $DEBUG

          Thread.kill( thr ) #.kill if not thr.kill?

          end
          @inner_pool.delete(thr)
        rescue => bang
        puts "could not kill thread #{thr}"
        puts bang
        puts bang.backtrace if $DEBUG
        end
      end
      @inner_pool_cv.signal

    end

    def stop()
      # TODO: real stop/pause function
      cancel()
    end

    def fileExists?(request, prefs={})
      begin
        t_request, t_response = doRequest(request, prefs)
        #puts t_response.status
        status = t_response.status
        return false if status.empty?
        return true, t_request, t_response if status =~ /^403/
        return false, t_request, t_response if status =~ /^40\d/
        if status =~ /^50\d/
         # puts "* ignore server errors #{Watobo::Conf::Scanner.ignore_server_errors.class}"
          return false, t_request, t_response if Watobo::Conf::Scanner.ignore_server_errors
        end

        #puts @settings[:custom_error_patterns] 

        if @settings.has_key? :custom_error_patterns
          @settings[:custom_error_patterns].each do |pat|
          # puts pat
            t_response.headers.each do |hl|
              return false if hl =~ /#{pat}/
            end
            # puts t_response.body.class
            unless t_response.body.nil?
              #  puts "* check body"
              #  puts t_response.body
              return false if t_response.body =~ /#{pat}/
            end
          end
        end
        # if t_request.path_ext != ""
        #TODO: Check for custom error pages
        # end

        return true, t_request, t_response
      rescue => bang
      end
      return false, nil, nil
    end
    
    def log_console(msg)
      puts "[#{self}] #{msg}"
    end

    # +++ run_checks  +++
    # + function: wrapper function for doRequest(r). Needed for additional checks like smartchecks.
    #
    # :run_passive_checks false,
    # :do_login

    def run_checks_UNUSED(chat, opts={})
      begin
      # reset() # reset variables first
        @@status = :running
        check_opts = { :run_passive_checks => false}
        check_opts.update opts
        @settings.update opts

        updateSessionSettings(opts)
        #  puts @session.to_yaml

        @@proxy = opts[:proxy] if opts[:proxy]
     #   @@max_checks = opts[:max_parallel_checks] if opts.has_key? :max_parallel_checks
     @@max_checks = Watobo::Conf::Scanner.max_parallel_checks

        do_test(chat) { |request, response|
          begin
           
            if request and response then
              if check_opts[:run_passive_checks] then

              nc = Watobo::Chat.new(request, response, :id => 0)
              #   @project.runPassiveModules(nc)

              end

            end
          rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          end

        }

      rescue => bang
      puts bang
      puts bang.backtrace if $DEBUG

      end

    end
    

    def do_test_UNUSED(chat, &block)
      # puts chat.request.site
      tlist = []
      @inner_pool = []
      generateChecks(chat) do |check|
        unless @@status == :stopped
          @@pool_mutex.synchronize do
            while  @@check_count > @@max_checks or @@login_in_progress
              puts "[#{self.class.to_s.gsub(/Watobo::Modules::Active::/,'')}] do_test on chat [#{chat.id}]: waiting .. #{@@check_count}/#{@@max_checks}" if $DEBUG
              @@pool_cv.wait(@@pool_mutex)
            end
            @@check_count += 1
          end

          @inner_pool << Thread.new(check) { |c|
            begin

              if c.respond_to? :call
              request, response = c.call            
              yield request, response if block_given?
              
              end
            rescue => bang
            # puts "!!!ERROR: running check in #{self.class}"
              puts bang
              puts bang.backtrace if $DEBUG
              # raise
            ensure

              @@pool_mutex.synchronize do
                @@check_count -= 1
                notify(:check_finished, self, request, response)
                #@inner_pool.delete Thread.current
              end
            @@pool_cv.signal

            end
          }
         # puts "[#{self.class.to_s.gsub(/Watobo::Modules::Active::/,'')}] [#{chat.id}]: INNER POOL - #{@inner_pool.length} " 
        end
      end

      @inner_pool.each {|t| t.join }
      puts ">>>>  #{self.class} on chat[#{chat.id}] ... finished!\n"
    end
    
    def check_name
      info = self.class.instance_variable_get("@info")
      return nil if info.nil?
      return info[:check_name]
    end

    def initialize(session_name=nil, prefs={})
      #@project = project
      super(session_name, prefs)
      
      @enabled = true
      # @status = "ready"
      @counters = Hash.new

      #TODO: change @settings to @session, if no bugs!
      @settings = @session
      #    @settings = {
      #      :custom_error_patterns => [],
      #      :excluded_parms => []
      #    }

      @@max_checks = prefs[:max_parallel_checks] unless prefs[:max_parallel_checks].nil?
      @running_chats = []

      @numChecks = 0
      @progress = 0
      @check_threads = []

      @inner_pool = []
      @inner_pool_mutex = Mutex.new
      @inner_pool_cv = ConditionVariable.new

      @checks_cv = ConditionVariable.new
      @checks_mutex = Mutex.new

     

    end
  end
end
