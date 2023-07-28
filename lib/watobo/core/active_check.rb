# @private 
module Watobo #:nodoc: all
  # class ActiveCheck < Watobo::Session # Base Class for Passive Checks
  class ActiveCheck < Watobo::Net::Http::Session # Base Class for Passive Checks
    include Watobo::CheckInfoMixin

    attr :info
    attr :numChecks

    #   @@running_checks = 0
    #@@max_checks = 5
    #@@check_count = 0
    #@@pool = []
    #@@pool_mutex = Mutex.new
    #@@pool_cv = ConditionVariable.new

    @@status = :running # :running, :paused, :canceled
    @@lock = Mutex.new

    @info = {
      :check_name => '', # name of check which briefly describes functionality, will be used for tree and progress views
      :check_group => 'Misc', # groupname of check, will be used to group checks, e.g. :Generic, SAP, :Enumeration
      :description => '', # description of checkfunction
      :author => "not modified", # author of check
      :version => "unversioned", # check version
      :target => nil # reserved

    }

    @finding = {
      :title => 'untitled', # [String] title name, used for finding tree
      :check_pattern => nil, # [String] regex of vulnerability check if possible, will be used for highlighting
      :proof_pattern => nil, # [String] regex of finding proof if possible, will be used for highlighting
      :threat => '', # threat of vulnerability, e.g. loss of information
      :measure => '', # measure
      :class => "undefined", # [String] vulnerability class, e.g. Stored XSS, SQL-Injection, ...
      :subclass => nil, # reserved
      :type => FINDING_TYPE_UNDEFINED, # FINDING_TYPE_HINT, FINDING_TYPE_INFO, FINDING_TYPE_VULN
      :chat => nil, # related chat must be linked
      :rating => VULN_RATING_UNDEFINED, #
      :cvss => "n/a", # CVSS Base Vector
      :icon => nil, # Icon Type
      :timestamp => nil # timestamp
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
        # puts finding_info.to_yaml
        new_details.update(finding_info)

        new_details.update(details)
        new_details[:tstamp] = now

        id_string = ''
        id_string << request.site.to_s
        id_string << request.path.to_s
        id_string << new_details[:test_item] if new_details[:test_item]
        id_string << new_details[:class] if new_details[:class]
        id_string << new_details[:title] if new_details[:title]

        if id_string == '' then
          id_string = (Time.now.to_i + rand(10000)).to_s
        end
        #

       new_details[:fid] = Digest::MD5.hexdigest(id_string)

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
      @numChecks
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
        pnames.select! { |p| !@settings[:excluded_parms].include? p }
      rescue => bang
        # puts "! settings 'excluded_parms' missing !"
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

    def enabled?
      r = nil
      @enable_mutex.synchronize do
        r = @enabled ? true : false
      end
      r
    end

    def enable
      @enable_mutex.synchronize do
        @enabled = true
      end
    end

    def disable
      @enable_mutex.synchronize do
        @enable = false
      end
    end

    def checkid()
      cn = self.class.to_s.downcase
      cn.gsub!(/.*::/, '')

      t_hex = Time.now.to_i.to_s(16)

      cid = "#{cn}#{t_hex}"

      cid
    end

    def generateChecks(chat)
      raise "Missing method generateChecks()!!!"
    end

    def stop()
      # TODO: real stop/pause function
      cancel()
    end

    def fileExists?(request, prefs = {})
      begin
        t_request, t_response = doRequest(request, prefs)
        # first custom error patterns are checked
        return false unless t_response
        status = t_response.status
        # if @settings.has_key? :custom_error_patterns
        custom_error_patterns.each do |pat|
          binding.pry unless pat.is_a? String
          if pat =~ /^[0-9a-zA-Z]{10,}$/
            return [false, t_request, t_response] if Watobo::Utils.responseHash(t_request, t_response) == pat
          end
          return [false, t_request, t_response] if t_response.to_s =~ /#{pat}/
        end
        # end
        #
        # if @settings.has_key? :custom_error_patterns
        #  @settings[:custom_error_patterns].each do |pat|
        #    t_response.headers.each do |hl|
        #      return false, t_request, t_response if hl =~ /#{pat}/
        #    end

        #    unless t_response.body.nil?
        #      return false, t_request, t_response if t_response.body.to_s =~ /#{pat}/
        # also check if pattern exists in plain text representation of body
        #      return false, t_request, t_response if Nokogiri::HTML(t_response.body.to_s).text =~ /#{pat}/
        #    end
        #  end
        # end

        return [true, t_request, t_response] if status =~ /^405/ # Method Not Allowed

        return [false, t_request, t_response] if status.empty?

        # return false, t_request, t_response if status =~ /^404/ # Not Found
        # return false, t_request, t_response if status =~ /^400/ # Bad Request
        return [false, t_request, t_response] if status =~ /^40/ # expect all 40ers as no valid response

        if status =~ /^50\d/
          # puts "* ignore server errors #{Watobo::Conf::Scanner.ignore_server_errors.class}"
          return[false, t_request, t_response] if Watobo::Conf::Scanner.ignore_server_errors
        end

        # puts @settings[:custom_error_patterns]

        # return false if status is 200 (OK) but has no body
        if t_response.status =~ /^200/ && !t_response.has_body?
          return [false, t_request, t_response]
        end

        return [true, t_request, t_response]
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return [false, nil, nil]
    end

    def log_console(msg)
      puts "[#{self}] #{msg}"
    end

    def check_name
      info = self.class.instance_variable_get("@info")
      return nil if info.nil?
      return info[:check_name]
    end

    def initialize(session_name = nil, prefs = {})
      #@project = project
      super(session_name, prefs)

      @enabled = true
      # @status = "ready"
      @counters = Hash.new

      # TODO: change @settings to @session, if no bugs!
      # @settings = @session
      #    @settings = {
      #      :custom_error_patterns => [],
      #      :excluded_parms => []
      #    }

      @@max_checks = prefs[:max_parallel_checks] unless prefs[:max_parallel_checks].nil?
      @running_chats = []

      @numChecks = 0
      @progress = 0
      @check_threads = []

      # @inner_pool = []
      #@inner_pool_mutex = Mutex.new
      #@inner_pool_cv = ConditionVariable.new

      #@checks_cv = ConditionVariable.new
      #@checks_mutex = Mutex.new

      @enable_mutex = Mutex.new

      # in active checks we need dynamic/controllable timeouts, so that e.g. the scanner has
      # controll over the time-out behaviour
      @timeout_dyn = 60

    end
  end
end
