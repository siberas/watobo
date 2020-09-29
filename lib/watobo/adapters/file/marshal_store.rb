# @private 
module Watobo #:nodoc: all
  class FileSessionStore < SessionStore
    def num_chats
      get_file_list(@conversation_path, "*-chat*").length
    end

    def num_findings
      get_file_list(@findings_path, "*-finding*").length
    end

    def add_finding(finding)
      return false unless finding.respond_to? :request
      return false unless finding.respond_to? :response

      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding.mrs")
      unless File.exist?(finding_file)
        save_finding(finding_file, finding)
        return true
      end
      false
    end

    def delete_finding(finding)
      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding")
      File.delete finding_file if File.exist? finding_file
      file = finding_file + ".yml"
      File.delete file if File.exist? file
      file = finding_file + ".mrs"
      File.delete file if File.exist? file

    end

    def save_finding(fname, finding)
      File.open(fname, 'wb') {|f|
        f.print Marshal::dump(finding.to_h)
      }
    end

    def save_chat(file, chat)
      File.open(file, 'wb') {|f|
        f.print Marshal::dump(chat.to_h)
      }
    end

    def update_finding(finding)
      finding_file = File.join("#{@findings_path}", "#{finding.id}-finding.mrs")

      if File.exist?(finding_file) then
        save_finding(finding_file, finding)
      end

    end

    def open_scan(scan_name, &block)
      begin

        return false if scan_name.nil?
        return false if scan_name.empty?

        scan_name_clean = scan_name.gsub(/[:\\\/\.]*/, '_')
        # puts ">> scan_name"
        path = File.join(@scanlog_path, scan_name_clean)

        return nil unless File.exist? path


        return scan_chats
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return nil

    end

    def list_scans
      Dir["#{@scanlog_path}/*"].map {|x| x}.sort
    end

    alias :scans :list_scans

    # @param scan_name [String] the scan location. This can be the shortened scan name of
    # the current project directory, or an absolute directory
    # @yield chat [Chat]
    # @returns scan-chats [Array]
    def load_scan(scan_name, &block)
      scan_chats = []
      scan_dir = scan_name
      unless File.exist?(scan_dir)
        scan_dir = File.join(@scanlog_path, scan_name)
        return nil unless File.exist? scan_dir
      end

      get_file_list(scan_dir, "log_*").each do |fname|
        #puts
        chat = nil
        if fname =~ /\.mrs$/
          chat = Watobo::Utils.loadChatMarshal(fname)
        elsif fname =~ /\.yml$/
          chat = Watobo::Utils.loadChatYAML(fname) unless list.include?(fname.gsub(/yml$/, 'mrs'))
        end
        next if chat.nil?
        yield chat if block_given?
        scan_chats << chat
      end
      scan_chats
    end

    # add_scan_log
    # adds a chat to a specific log store, e.g. if you want to log scan results.
    # needs a scan_name (STRING) as its destination which will be created
    # if the scan name does not exist.
    def add_scan_log(chat, scan_name = nil)
      #puts "* add_scan_log"

      return false unless chat.respond_to? :request
      return false unless chat.respond_to? :response
      begin

        return false if scan_name.nil?
        return false if scan_name.empty?

        scan_name_clean = scan_name.gsub(/[:\\\/\.]+/, '_')
        # puts ">> scan_name"
        path = File.join(@scanlog_path, scan_name_clean)

        Dir.mkdir path unless File.exist? path

        file = File.join(path, 'log_' + Time.now.to_f.to_s + '.mrs')

        unless File.exist?(file)
          File.open(file, 'wb') {|fh|
            fh.print Marshal::dump(chat.to_h)
          }
        end

        return true
      rescue => bang
        puts bang
        puts bang.backtrace if $DEBUG
      end
      return false
    end

    def add_chat(chat)
      return false unless chat_valid? chat
      chat_file = File.join("#{@conversation_path}", "#{chat.id}-chat.mrs")

      unless File.exist?(chat_file)
        File.open(chat_file, "wb") {|fh|
          fh.print Marshal::dump(chat.to_h)
        }
        chat.file = chat_file
        return true
      end
      return false
    end

    def each_chat(&block)
      list = get_file_list(@conversation_path, "*-chat*")
      list.each do |fname|
        #puts 
        chat = nil
        if fname =~ /\.mrs$/
          chat = Watobo::Utils.loadChatMarshal(fname)
        elsif fname =~ /\.yml$/
          chat = Watobo::Utils.loadChatYAML(fname) unless list.include?(fname.gsub(/yml$/, 'mrs'))
        end
        next if chat.nil?
        yield chat if block_given?
      end
    end

    def each_finding(&block)
      list = get_file_list(@findings_path, "*-finding*")
      list.each do |fname|
        f = nil
        if fname =~ /\.mrs$/
          f = Watobo::Utils.loadFindingMarshal(fname)
        elsif fname =~ /\.yml$/
          f = Watobo::Utils.loadFindingYAML(fname) unless list.include?(fname.gsub(/yml$/, 'mrs'))
        end
        next if f.nil?
        yield f if block_given?
      end
    end

    def initialize(project_name, session_name)

      wsp = Watobo.workspace_path
      return false unless File.exist? wsp
      puts "* using workspace path: #{wsp}" if $DEBUG

      @log_file = nil
      @log_lock = Mutex.new

      @project_path = File.join(wsp, project_name)
      unless File.exist? @project_path
        puts "* create project path: #{@project_path}" if $DEBUG
        Dir.mkdir(@project_path)
      end

      @project_config_path = File.join(@project_path, ".config")
      Dir.mkdir @project_config_path unless File.exist? @project_config_path

      @session_path = File.join(@project_path, session_name)

      unless File.exist? @session_path
        puts "* create session path: #{@session_path}" if $DEBUG
        Dir.mkdir(@session_path)
      end

      @session_config_path = File.join(@session_path, ".config")
      Dir.mkdir @session_config_path unless File.exist? @session_config_path

      sext = Watobo::Conf::General.session_settings_file_ext

      @session_file = File.join(@session_path, session_name + sext)
      @project_file = File.join(@project_path, project_name + Watobo::Conf::General.project_settings_file_ext)

      @conversation_path = File.expand_path(File.join(@session_path, Watobo::Conf::Datastore.conversations))

      @findings_path = File.expand_path(File.join(@session_path, Watobo::Conf::Datastore.findings))
      @log_path = File.expand_path(File.join(@session_path, Watobo::Conf::Datastore.event_logs_dir))
      @scanlog_path = File.expand_path(File.join(@session_path, Watobo::Conf::Datastore.scan_logs_dir))

      [@conversation_path, @findings_path, @log_path, @scanlog_path].each do |folder|
        if not File.exist?(folder) then
          puts "create path #{folder}"
          begin
            Dir.mkdir(folder)
          rescue SystemCallError => bang
            puts "!!!ERROR:"
            puts bang
          rescue => bang
            puts "!!!ERROR:"
            puts bang
          end
        end
      end

      @log_file = File.join(@log_path, session_name + ".log")

      #     @chat_files = get_file_list(@conversation_path, "*-chat")
      #     @finding_files = get_file_list(@findings_path, "*-finding")
    end

    def save_session_settings(group, session_settings)
      # puts ">> save_session_settings <<"
      file = Watobo::Utils.snakecase group.gsub(/\.yml/, '')
      file << ".yml"

      session_file = File.join(@session_config_path, file)
      puts "Dest.File: #{session_file}"
      #  puts session_settings.to_yaml
      # puts "---"
      Watobo::Utils.save_settings(session_file, session_settings)
    end

    def load_session_settings(group)
      # puts ">> load_session_settings : #{group}"
      file = Watobo::Utils.snakecase group.gsub(/\.yml/, '')
      file << ".yml"

      session_file = File.join(@session_config_path, file)
      # puts "File: #{session_file}"
      #  puts "---"

      s = Watobo::Utils.load_settings(session_file)
      s
    end

    def save_project_settings(group, project_settings)
      # puts ">> save_project_settings : #{group}"
      file = Watobo::Utils.snakecase group.gsub(/\.yml/, '')
      file << ".yml"

      project_file = File.join(@project_config_path, file)
      # puts "Dest.File: #{project_file}"
      # puts project_settings.to_yaml
      # puts "---"
      Watobo::Utils.save_settings(project_file, project_settings)

    end

    def load_project_settings(group)
      # puts ">> load_project_settings : #{group}"
      file = Watobo::Utils.snakecase group.gsub(/\.yml/, '')
      file << ".yml"

      project_file = File.join(@project_config_path, file)
      # puts "File: #{project_file}"
      # puts "---"

      s = Watobo::Utils.load_settings(project_file)
      s

    end

    def logs
      l = ''
      @log_lock.synchronize do
        l = File.open(@log_file).read
      end
      l
    end

    def logger(message, prefs = {})
      opts = {:sender => "unknown", :level => Watobo::Constants::LOG_INFO}
      opts.update prefs
      return false if @log_file.nil?
      begin
        t = Time.now
        now = t.strftime("%m/%d/%Y @ %H:%M:%S")
        log_message = [now]
        log_message << "#{opts[:sender]}"
        if message.is_a? Array
          log_message << message.join("\n| ")
          log_message << "\n-"
        else
          log_message << message
        end
        @log_lock.synchronize do
          File.open(@log_file, "a") do |lfh|
            lfh.puts log_message.join("|")
          end
        end
      rescue => bang
        puts bang
      end

    end

    private

    def chat_valid?(chat)
      return false unless chat.respond_to? :request
      return false unless chat.respond_to? :response
      true
    end

    def get_file_list(path, pattern)
      fl = Dir["#{path}/#{pattern}"].sort_by {|x| File.basename(x).sub(/[^0-9]*/, '').to_i}

      fl
    end

  end

end