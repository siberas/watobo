# @private 
module Watobo #:nodoc: all

  class Project

    attr :chats
    attr_accessor :findings
    attr :scan_settings
    attr :forward_proxy_settings
    attr :date
    attr :project_name
    attr :session_name
    #attr :session_store
    attr_accessor :settings

    attr :active_checks
    attr :passive_checks
    attr_accessor :plugins
    attr_accessor :excluded_chats

    attr :target_filter

    def subscribe(event, &callback)
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def notify(event, *args)
      if @event_dispatcher_listeners[event]
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

    def sessionSettingsFile
      @session_file
    end

    def projectSettingsFile
      @project_file
    end

    def session_settings()
      s = YAML.load(YAML.dump(scan_settings))
      sf = [:logout_signatures, :non_unique_parms, :login_chat_ids, :excluded_chats, :csrf_request_ids, :scope]
      s.each_key do |k|
        s.delete k unless sf.include? k
      end
      s
    end

    def getLoginChats()
      @scan_settings[:login_chat_ids] ||= []
      login_chats = []
      @scan_settings[:login_chat_ids].each do |cid|
        chat = Watobo::Chats.get_by_id(cid)
        login_chats.push chat if chat
      end
      login_chats
    end

    def getWwwAuthentication()
      @scan_settings[:www_auth]
    end

    def getLoginChatIds()
      #p @settings[:login_chat_ids]
      # p @settings.to_yaml
      @scan_settings[:login_chat_ids] ||= []
      @scan_settings[:login_chat_ids]
    end

    def setLoginChatIds(ids)
      @scan_settings[:login_chat_ids] = ids if ids.is_a? Array
    end

    def getSidPatterns
      @scan_settings[:sid_patterns]
    end

    def setProxyOptions(proxy_prefs)
      @forward_proxy_settings = proxy_prefs

      @sessionController.addProxy(getCurrentProxy())
    end

    # gives the currently selected proxy
    # format <host>:<port>
    def getCurrentProxy()
      c_proxy = nil
      begin
        name = @forward_proxy_settings[:default_proxy]
        cproxy = @forward_proxy_settings[name]
        return cproxy
      rescue
        puts "! no proxy settings available"
      end
      return nil
    end


    def getLogoutSignatures
      @scan_settings[:logout_signatures]
    end

    def getCSRFPatterns
      @scan_settings[:csrf_patterns]
    end

    # setCSRFRequest
    # =Parameters
    # request: test request which requires csrf handling
    # ids:      csrf request ids of current conversation
    # patterns: csrf patterns for identifiying and updating tokens
    def setCSRFRequest(request, ids, patterns = [])
      puts "* setting CSRF Request"
      # puts request.class
      #  puts request
      urh = uniqueRequestHash(request)
      @scan_settings[:csrf_request_ids][urh] = ids
      @scan_settings[:csrf_patterns].concat patterns unless patterns.empty?
      @scan_settings[:csrf_patterns].uniq!
      notify(:settings_changed)
    end

    def getCSRFRequestIDs(request)
      urh = request.uniq_hash
      Watobo::Conf::Scanner.csrf_request_ids ||= {}
      Watobo::Conf::Scanner.csrf_request_ids = {} if Watobo::Conf::Scanner.csrf_request_ids.is_a? Array
      ids = Watobo::Conf::Scanner.csrf_request_ids[urh]
      # puts "* found csrf req ids #{ids}"
      ids = [] if ids.nil?
      ids
    end

    def setLogoutSignatures(ls)
      @scan_settings[:logout_signatures] = ls if ls.is_a? Array
    end

    # Helper function to get all necessary preferences for starting a scan.
    def getScanPreferences()
      settings = {
          :smart_scan => @scan_settings[:smart_scan],
          :non_unique_parms => @scan_settings[:non_unique_parms],
          :excluded_parms => @scan_settings[:excluded_parms],
          :sid_patterns => @scan_settings[:sid_patterns],
          :csrf_patterns => @scan_settings[:csrf_patterns],
          :run_passive_checks => false,
          :login_chat_ids => [],
          :proxy => getCurrentProxy(),
          :login_chats => getLoginChats(),
          :max_parallel_checks => @scan_settings[:max_parallel_checks],
          :logout_signatures => @scan_settings[:logout_signatures],
          :custom_error_patterns => @scan_settings[:custom_error_patterns],
          :scan_session => self.object_id,
          :www_auth => @scan_settings[:www_auth].nil? ? Hash.new : @scan_settings[:www_auth],
          :client_certificates => @scan_settings[:client_certificates],
          :session_store => @session_store
      }
      return settings
    end

    # returns a project/session specific ID needed for synchronising Sessions
    def getSessionID()
      sid = @settings[:project_name] + @settings[:session_name]
      return sid
    end

    def getClientCertificates()
      client_certs = @scan_settings[:client_certificates]
    end

    def setClientCertificates(certs)
      @scan_settings[:client_certificates] = certs
    end

    def add_client_certificate(client_cert = {})
      return false unless client_cert.is_a? Hash
      [:site, :certificate_file, :key_file].each do |p|
        return false unless client_cert.has_key? p
      end
      cs = @scan_settings[:client_certificates]
      site = client_cert[:site]
      if cs.has_key? site
        cs[site][certificate] = nil
        cs[site][key] = nil

      end

    end

    def client_certificates=(certs)
      @scan_settings[:client_certificates] = certs
      cs = @scan_settings[:client_certificates]
      cs.each_key do |site|
        unless cs[site].has_key? :ssl_client_cert
          crt_file = cs[site][:certificate_file]
          if File.exist?(crt_file)
            puts "* loading certificate #{crt_file}" if $DEBUG
            cs[site][:ssl_client_cert] = OpenSSL::X509::Certificate.new(File.read(crt_file))
          end
        end

        unless cs[site].has_key? :ssl_client_key
          key_file = cs[site][:key_file]
          if File.exist?(key_file)
            puts "* loading private key #{key_file}" if $DEBUG
            password = cs[site][:password].empty? ? nil : cs[site][:password]
            cs[site][:ssl_client_key] = OpenSSL::PKey::RSA.new(File.read(key_file), password)
          end
        end
      end
    end

    def getScanPolicy()
      @settings[:policy]
    end

    def uniqueRequestHash(request)
      begin
        extend_request(request) unless request.respond_to? :site
        hashbase = request.site + request.method + request.path
        request.get_parm_names.sort.each do |p|
          # puts "URL-Parm: #{p}"
          if @scan_settings[:non_unique_parms].include?(p) then
            hashbase += p + request.get_parm_value(p)
          else
            hashbase += p
          end

        end
        request.post_parm_names.sort.each do |p|
          # puts "POST-Parm: #{p}"
          if @scan_settings[:non_unique_parms].include?(p) then
            hashbase += p + request.post_parm_value(p)
          else
            hashbase += p
          end

        end
        # puts hashbase
        return Digest::MD5.hexdigest(hashbase)
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
        return nil
      end
    end

    def updateSettings(new_settings)
      #  new_settings.keys.each do |k|
      #    @settings[k] = new_settings[k]
      #  end
      @scan_settings.update new_settings
    end

    def projectName
      @settings[:project_name]
    end

    def sessionName
      @settings[:session_name]
    end

    def interceptPort
      @settings[:project_name]
    end


    def runLogin
      @sessionMgr.runLogin(loginChats)
    end

    def has_scope?()
      return false if @scan_settings[:scope].empty?
      @scan_settings[:scope].each_key do |k|
        return true if @scan_settings[:scope][k][:enabled] == true
      end
      return false
    end

    def scope
      @scan_settings[:scope]
    end

    def scope=(scope)
      @scan_settings[:scope] = scope
    end

    def setScope(scope)
      @scan_settings[:scope] = scope
    end

    def setWwwAuthentication(www_auth)
      @scan_settings[:www_auth] = www_auth
    end

    def setCSRFPatterns(patterns)
      @scan_settings[:csrf_patterns] = patterns
    end

    def add_login_chat_id(id)
      @scan_settings[:login_chat_ids] ||= []
      @scan_settings[:login_chat_ids].push id
    end

    def addToScope(site)
      return false if !@scan_settings[:scope][site].nil?

      scope_details = {
          :site => site,
          :enabled => true,
          :root_path => '',
          :excluded_paths => [],
      }

      @scan_settings[:scope][site] = scope_details
      return true
    end


    def setupProject(progress_window = nil)
      begin
        puts "DEBUG: Setup Project" if $DEBUG and $debug_project

        importSession()

        Watobo::EgressHandlers.init


      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
    end

    # returns all chats which are in the target scope

    def chatsInScope_UNUSED(chats = nil, scope = nil)
      scan_prefs = @scan_settings
      unique_list = Hash.new
      chatlist = chats.nil? ? @chats : chats
      new_scope = scope.nil? ? scan_prefs[:scope] : scope
      # puts new_scope.to_yaml
      cis = []
      chat_in_scope = nil
      chatlist.each do |chat|
        next if scan_prefs[:excluded_chats].include?(chat.id)
        uch = uniqueRequestHash(chat.request)

        next if unique_list.has_key?(uch) and scan_prefs[:smart_scan] == true
        unique_list[uch] = nil

        chat_in_scope = chat
        # filter by targets first
        new_scope.each do |s, c_scope|
          chat_in_scope = nil

          if chat.request.site == c_scope[:site] then
            chat_in_scope = chat

            if chat_in_scope and c_scope[:root_path] != ''
              chat_in_scope = (chat.request.path =~ /^(\/)?#{c_scope[:root_path]}/i) ? chat : nil
            end

            if chat_in_scope and c_scope[:excluded_paths] and c_scope[:excluded_paths].length > 0
              c_scope[:excluded_paths].each do |p|
                if (chat.request.url.to_s =~ /#{p}/i)
                  chat_in_scope = nil
                  break
                end
              end
            end
          end
          cis.push chat_in_scope unless chat_in_scope.nil?
        end
      end
      cis
    end


    def siteSSL?(site)
      @chats.each do |c|
        if c.request.site == site
          return true if c.request.proto =~ /https/
          return false
        end
      end
    end

    #
    # INITIALIZE
    #
    #
    def initialize(project_settings)

      puts "DEBUG: Initializing Project" if $DEBUG
      @event_dispatcher_listeners = Hash.new
      @settings = {}

      @active_checks = []
      # @passive_checks = []
      @plugins = []

      @chats = []
      @findings = Hash.new
      @findings_lock = Mutex.new
      @chats_lock = Mutex.new

      # puts project_prefs.to_yaml
      #setDefaults()

      # reset counters
      Watobo::Chat.resetCounters
      Watobo::Finding.resetCounters

      # UPDATE SETTINGS
      @settings.update(project_settings)

      @scan_settings = Watobo::Conf::Scanner.dump
      @forward_proxy_settings = Watobo::Conf::ForwardingProxy.dump

      Watobo::ClientCertStore.load

      # raise ArgumentError, "No SessionStore Defined" unless @settings.has_key? :session_store

      # @session_store = @settings[:session_store]
      #  @passive_checks = @settings[:passive_checks] if @settings.has_key? :passive_checks

      # @settings[:passive_checks].each do |pm|
      #   pc = pm.new(self)
      #   pc.subscribe(:new_finding){ |nf| addFinding(nf) }
      #   @passive_checks << pc
      # end

      #      @active_checks = @settings[:active_checks]
      #@settings[:active_checks].each do |am|
      #  ac = am.new(self)
      #  puts "subscribe to #{ac.class}"
      #  ac.subscribe(:new_finding){ |nf| 
      #   puts "[subscribe] new_finding"
      #    addFinding(nf)
      #     }
      #  @active_checks << ac
      #end

      @date = Time.now.to_i
      # @date_str = Time.at(@date).strftime("%m/%d/%Y@%H:%M:%S")

      @sessionController = Watobo::Session.new(self)

        # @sessionController.addProxy(getCurrentProxy())

    end


    private

    def importSession
      chats = Watobo::DataStore.chat_files.map { |f| Watobo::Utils.loadChatMarshal(f) }
      puts "Got #{chats.length} Chats"
      Watobo::Chats.set chats
        #notify(:update_chats, chats)
      findings = Watobo::DataStore.finding_files.map{|f| Watobo::Utils.loadFindingMarshal(f) }
      puts "Got #{findings.length} Findings"
      Watobo::Findings.set findings
    end

    def importSession_UNUSED()
      num_chats = Watobo::DataStore.num_chats
      num_findings = Watobo::DataStore.num_findings
      num_imports = num_chats + num_findings
      notify(:update_progress, :progress => 0, :total => num_imports, :task => "Import Conversation")
      Watobo::DataStore.each_chat do |c|
        notify(:update_progress, :increment => 1, :job => "chat #{c.id}")
        Watobo::Chats.add(c, :run_passive_checks => false) if c
      end

      notify(:update_progress, :task => "Import Findings")
      Watobo::DataStore.each_finding do |f|
        notify(:update_progress, :increment => 1, :job => "finding #{f.id}")
        Watobo::Findings.add(f, :notify => true) if f
      end

    end
  end
end # Watobo
