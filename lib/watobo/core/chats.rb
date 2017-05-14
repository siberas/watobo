# @private
module Watobo#:nodoc: all
  class Chats
    @chats = []
    @chats_lock = Mutex.new
    @event_dispatcher_listeners = Hash.new


    def self.subscribe(event, &callback)
      (@event_dispatcher_listeners[event] ||= []) << callback
    end

    def self.clearEvents(event)
      @event_dispatcher_listeners[event] ||= []
      @event_dispatcher_listeners[event].clear
    end

    def self.notify(event, *args)
      if @event_dispatcher_listeners[event]
        @event_dispatcher_listeners[event].each do |m|
          m.call(*args) if m.respond_to? :call
        end
      end
    end

    def self.reset
      @chats = []
      @event_dispatcher_listeners = Hash.new
    end

    def self.load

    end

    def self.select(site, opts={}, &block)
      o = {
        :dir => "",
        #:file => nil,
        :method => nil,
        :max_count => 0
      }
      o.update opts
      o[:dir].strip!
      o[:dir].gsub!(/^\//,"")

      matches = []
      @chats.each do |c|
        if c.request.site == site then
          matches.push c if o[:dir] == c.request.dir
          yield c if block_given?
        end
        return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
      end
      return matches

    end

    def self.sites(prefs={}, &block)
      list = Hash.new

      cprefs = { :in_scope => false,
        :ssl => false
      }
      cprefs.update prefs

      Watobo::Chats.each do |chat|
        next if list.has_key?(chat.request.site)
        site = chat.request.site
        next if cprefs[:in_scope] == true and not Watobo::Scope.match_site?(site)
        next if cprefs[:ssl] and not chat.use_ssl?

        yield site if block_given?
        list[site] = nil

      end
      return list.keys
    end

    def self.dirs(site, list_opts={}, &block)
      opts = { :base_dir => "",
        :include_subdirs => true
      }
      opts.update(list_opts) if list_opts.is_a? Hash
      list = Hash.new
      @chats.each do |chat|
        next if chat.request.site != site
        next if list.has_key?(chat.request.path)
        next if opts[:base_dir] != "" and chat.request.path !~ /^#{Regexp.quote(opts[:base_dir])}/
        subdirs = chat.request.subDirs
        subdirs.each do |dir|
          next if dir.nil?
          next if list.has_key?(dir)
          list[dir] = :path
          if opts[:include_subdirs] == true then
            yield dir if block_given?
          else
            d = dir.gsub(/#{Regexp.quote(opts[:base_dir])}/,"")
            yield dir unless d =~ /\// and block_given?
          # otherwise it is a subdir of base_dir
          end
        end
      end
    end

    def self.get_by_id(chatid)
      @chats_lock.synchronize do
        @chats.each do |c|
          if c.id.to_s == chatid.to_s then
          return c
          end
        end
      end
      return nil
    end

    def self.each(&block)
      if block_given?
        @chats_lock.synchronize do
          @chats.map{|c| yield c }
        end
      end
    end

    def self.to_a
      @chats
    end

    def self.length
      l = 0
      @chats_lock.synchronize do
        l = @chats.length
      end
      l
    end

    def self.in_scope(&block)
      scan_prefs = Watobo::Conf::Scanner.to_h
      #puts scan_prefs.to_yaml
      unique_list = Hash.new
      cis = []

      @chats.each do |chat|
        next if scan_prefs[:excluded_chats].include?(chat.id)
        uch = chat.request.uniq_hash

        next if unique_list.has_key?(uch) and scan_prefs[:smart_scan] == true
        unique_list[uch] = nil
        if Watobo::Scope.match_chat? chat
          cis << chat
          yield chat if block_given?
        end
      end
      cis
    end

    # only returns/yields chats wich match filter
    #
    #
    def self.filtered(filter, &block)
      #puts filter.to_yaml
      @uniq_chats = {}
      filtered_chats = []
      @chats.each do |chat|
        if match?(chat, filter)
          yield chat if block_given?
        filtered_chats << chat
        end
      end

      filtered_chats
    end

    def self.add(chat, prefs={})
      @chats_lock.synchronize do
        begin
          if chat.request.host then
            @chats << chat

            options = {
              :run_passive_checks => true,
              :notify => true
            }
            options.update prefs

            Watobo::PassiveScanner.add(chat) if options[:run_passive_checks] == true
            # puts "[#{self}] add"

            #@interface.addChat(self, chat) if @interface
            notify(:new, chat) if options[:notify] == true

            if chat.id != 0 then
              Watobo::DataStore.add_chat(chat)
            else
              puts "!!! Could not add chat #{chat.id}"
            end
          end

          # p "!P!"
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
    end

    private

    def self.match?(chat, filter)
      begin
        
        filtered = false
      # return false if filter[:ok_only] == true and chat.response.responseCode !~ /200/

        if filter[:unique]
          uniq_hash = chat.request.uniq_hash
          return false if @uniq_chats.has_key? uniq_hash
          @uniq_chats[uniq_hash] = nil
        end
        #puts "scope"
        if filter[:scope_only]
          return false unless Watobo::Scope.match_site?(chat.request.site)
        end
        # puts "* passed scope"
        if filter[:hide_tested]
        return false if chat.tested?
        end

        if filter.has_key?(:status_codes) and not filter[:status_codes].empty?
          return false if filter[:status_codes].find_index{|i| chat.response.status =~ /#{i}/}.nil?
        end

        if filter.has_key?(:mime_types) and not filter[:mime_types].empty?
          match = false
          filter[:mime_types].each do |mt|
            if chat.response.content_type =~ /#{mt}/i
            match = true
            end
          end
        return false if match == false
        end

        #puts "extensions"
        # puts "* passed hide tested"
        if filter[:hidden_extensions] == true
          return false if filter[:hidden_extension_patterns].include?(chat.request.doctype)
        end

        if filter[:show_extension_patterns]
          unless filter[:show_extension_patterns].empty? or filter[:show_extensions] == false
            return false unless filter[:show_extension_patterns].include?(chat.request.doctype)
          end
        end
        #return true if filter[:text].empty?
        # puts "url pattern"
        if filter[:url_pattern]
          unless filter[:url_pattern].empty?
            filtered = true
            return true if chat.request.first =~ /#{filter[:url_pattern]}/i
          #return false
          end
        end

        if filter[:request_pattern]
          unless filter[:request_pattern].empty?
            filtered = true
            return true if chat.request.join =~ /#{filter[:request_pattern]}/i
          #return false
          end
        end
        # puts filter.to_yaml
        # puts chat.response.responseCode
        if filter[:response_pattern]
          unless filter[:response_pattern].empty?
            filtered = true
            #return false if filter[:text_only] == true and chat.response.content_type !~ /(text|javascript|xml|json)/
            return true if chat.response.join.unpack("C*").pack("C*") =~ /#{filter[:response_pattern]}/i
          #return false
          end
        end

        return !filtered

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      false
    end
  end
end