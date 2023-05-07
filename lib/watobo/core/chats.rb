# @private
module Watobo #:nodoc: all
  class ChatsClazz

    include Watobo::Subscriber

    def initialize
      @chats = []
      @uniq_chats = {}
      @chats_lock = Mutex.new
      @event_dispatcher_listeners = Hash.new
    end

    def clear_uniq
      @uniq_chats = {}
    end

    def reset
      @chats = []
      @event_dispatcher_listeners = Hash.new
    end


    def load_marshaled(dir, options={}, &block)
      opts = {
        ext: 'mr*',
        clear: true
      }
      opts.update options
      @chats_lock.synchronize do
        @chats = [] if opts[:clear]
        Dir.glob("#{dir}/*.#{opts[:ext]}") do |f|
          chat = Watobo::Utils.loadChatMarshal(f)
          yield chat if block_given?
          @chats << chat
        end
      end
      true
    end


    # find_by_url
    def find_by_url(site, pattern, opts = {}, &block)
      o = {
          :method => nil,
          :max_count => 0,
          :reverse => false
      }
      o.update opts

      matches = []

      unless o[:reverse]
        @chats.each do |c|
          if c.request.site =~ /#{site}/ then
            if c.request.url.to_s =~ /#{pattern}/
              matches.push c
              yield c if block_given?
            end
          end
          return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
        end
      else
        @chats.reverse_each do |c|
          if c.request.site =~ /#{site}/ then
            if c.request.url.to_s =~ /#{pattern}/
              matches.push c
              yield c if block_given?
            end

          end
          return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
        end
      end
      return matches

    end

    # selects all chats containing a request param <name>
    def with_param(name, *location, &block)
      cwp = []
      @chats.each do |c|
        ps = c.request.parameters *location

        match = ps.select { |p| p.name =~ /^#{name}$/i }
        if match.length > 0

          cwp << c
          yield c if block_given?
        end
      end
      cwp
    end

    # select chats by request options
    #
    def select(site, opts = {}, &block)
      o = {
          :dir => "",
          #:file => nil,
          :method => nil,
          :max_count => 0,
          :reverse => false
      }

      o.update opts
      o[:dir].strip!
      o[:dir].gsub!(/^\//, "")

      matches = []

      unless o[:reverse]
        @chats.each do |c|
          if c.request.site == site then
            matches.push c if o[:dir] == c.request.dir
            yield c if block_given?
          end
          return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
        end
      else
        @chats.reverse_each do |c|
          if c.request.site == site then
            matches.push c if o[:dir] == c.request.dir
            yield c if block_given?
          end
          return matches if o[:max_count] > 0 and matches.length >= o[:max_count]
        end
      end
      return matches

    end

    def sites(prefs = {}, &block)
      list = Hash.new

      cprefs = {:in_scope => false,
                :ssl => false
      }
      cprefs.update prefs

      Watobo::Chats.each do |chat|
        next if chat.request.nil?

        next if list.has_key?(chat.request.site)
        site = chat.request.site

        if site.nil? and $VERBOSE
          puts "! No Site in request:"
          puts " - ChatID: #{chat.id}"
          puts " - Chat-Request:"
          puts chat.request
        end
        next if site.nil?
        next if cprefs[:in_scope] == true and not Watobo::Scope.match_site?(site)
        next if cprefs[:ssl] and not chat.use_ssl?

        yield site if block_given?
        list[site] = nil

      end
      return list.keys
    end

    # @return [Array] list of directory names
    #
    def dirs(site, list_opts = {}, &block)
      opts = {:base_dir => "",
              :include_subdirs => true,
              :recursive => false
      }
      opts.update(list_opts) if list_opts.is_a? Hash
      # remove leading slash from basedir
      opts[:base_dir] = opts[:base_dir].gsub(/^\//, '')

      dir_list = []
      @chats.each do |chat|
        next if chat.request.site != site
        next if dir_list.include?(chat.request.path)
        next if !opts[:base_dir].empty? and chat.request.path !~ /^#{Regexp.quote(opts[:base_dir])}/

        subdirs = chat.request.subDirs
        subdirs.each do |dir|
          next if dir.nil? or dir.empty?
          next if dir_list.include? dir
          # we need to check dir against base_dir because subDir function returns also minor path values
          next unless dir.match?(opts[:base_dir])

          if opts[:include_subdirs] == true
            yield dir if block_given?
            dir_list << "#{dir}"
          else
            d = dir.gsub(/#{Regexp.quote(opts[:base_dir])}/, '')
            d.gsub!(/^\//, '')
            unless d.match?(/\//)
              dir_list << "#{dir}"
              yield dir if block_given?
            end
          end
        end
      end
      dir_list.uniq!
      dir_list.sort_by { |dir| dir.length }
    end

    def get_by_id(chatid)
      @chats_lock.synchronize do
        @chats.each do |c|
          if c.id.to_i == chatid.to_i then
            return c
          end
        end
      end
      return nil
    end

    def get_by_response(response)
      @chats_lock.synchronize do
        @chats.each do |c|
          if c.response.object_id == response.object_id
            return c
          end
        end
      end
      return nil
    end

    def get_by_request(request)
      @chats_lock.synchronize do
        @chats.each do |c|
          if c.request.object_id == request.object_id
            return c
          end
        end
      end
      return nil
    end

    def each(&block)
      if block_given?
        @chats_lock.synchronize do
          @chats.map { |c| yield c }
        end
      end
    end

    def to_a
      a = []
      @chats_lock.synchronize do
        a = @chats.clone
      end
      a
    end

    def length
      l = 0
      @chats_lock.synchronize do
        l = @chats.length
      end
      l
    end

    alias :size :length

    def request_header_names(&block)
      headers = []
      @chats_lock.synchronize do
        @chats.each do |chat|
          chat.request.header_names do |header|
            unless headers.include?(header)
              headers << header
              yield header if block_given?
            end
          end
        end
      end
      headers
    end

    def in_scope(&block)
      scan_prefs = Watobo::Conf::Scanner.to_h
      #puts scan_prefs.to_yaml
      unique_list = Hash.new
      cis = []
      @chats_lock.synchronize do
        @chats.each do |chat|
          next if scan_prefs[:excluded_chats].include?(chat.id)
          uch = chat.request.uniq_hash

          next if uch.nil?

          next if unique_list.has_key?(uch) and scan_prefs[:smart_scan] == true
          unique_list[uch] = nil
          if Watobo::Scope.match_chat? chat
            cis << chat
            yield chat if block_given?
          end
        end
      end
      cis
    end

    # only returns/yields chats wich match filter
    #
    #
    def filtered(filter, &block)
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


    def set(chats)
      @chats_lock.synchronize do
        @chats = chats
        @chats.compact!
      end
    end

    def add(chat, prefs = {})
      options = {
          :run_passive_checks => true,
          :notify => true
      }
      options.update prefs


      begin
        if chat.request.host then

          @chats_lock.synchronize {
            chat.set_id @chats.size + 1
            @chats << chat
          }

          notify(:chat_added, chat) if options[:notify] == true

          if chat.id > 0 then
            Watobo::DataStore.add_chat(chat)
          else
            puts "!!! Wrong chat.id! must be > 0 #{chat.id}"
          end
        end

          # p "!P!"
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end

    end

    def match?(chat, filter)
      begin
        @uniq_chats ||= {}
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

        if filter[:expression] and !!filter[:expression_enabled]
          unless filter[:expression].to_s.strip.empty?
            expr_filter = Proc.new() { |chat| eval(filter[:expression]) }
            begin
              return false unless expr_filter.call(chat)
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          end
        end

        if filter.has_key?(:status_codes) and not filter[:status_codes].empty?
          return false if filter[:status_codes].find_index { |i| chat.response.status =~ /#{i}/ }.nil?
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

        if filter[:hidden_extensions] == true
          return false if filter[:hidden_extension_patterns].include?(chat.request.doctype)
        end

        if filter[:show_extension_patterns]
          unless filter[:show_extension_patterns].empty? or filter[:show_extensions] == false
            return false unless filter[:show_extension_patterns].include?(chat.request.doctype)
          end
        end

        negate = filter.has_key?(:negate_pattern_search) ? filter[:negate_pattern_search] : false

        if filter[:url_pattern] && !filter[:url_pattern].empty?
          match = chat.request.first =~ /#{filter[:url_pattern]}/i
          return true if (match && !negate) || (!match && negate)
          return false
        end

        if filter[:request_pattern] && !filter[:request_pattern].empty?
          match = chat.request.join =~ /#{filter[:request_pattern]}/i
          return true if (match && !negate) || (!match && negate)
          return false
        end

        if filter[:response_pattern] && !filter[:response_pattern].empty?
          match = chat.response.join.unpack("C*").pack("C*") =~ /#{filter[:response_pattern]}/i
          return true if (match && !negate) || (!match && negate)
          return false
        end

        if filter[:comment_pattern] && !filter[:comment_pattern].empty?
          match = chat.comment =~ /#{filter[:comment_pattern]}/i
          return true if (match && !negate) || (!match && negate)
          return false
        end

        return true

      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      false
    end
  end

  Chats = ChatsClazz.new

end