module Watobo #:nodoc: all
  module Plugin
    class Filescanner

      extend Forwardable

      def_delegators :@scanner, :sum_progress, :sum_total, :status, :running?, :finished?

      attr :settings, :request, :file_list, :chat_list

      # @return [Object] Watobo::Scanner3
      def run(prefs={})
        scan_prefs = Watobo.project.getScanPreferences
        scan_prefs.update prefs
        # create
        @scanner.run(scan_prefs)

      end

      def stop
        # stop scanner
      end

      # @return [Hash]
      # {
      #   total: 100,
      #   progress: 33,
      #   state: :running
      # }
      def progress
        {
            total: sum_total,
            progress: sum_progress,
            state: :running # :running, :finished
        }
      end


      # @param request [Object] Watobo::Request or string
      # @param prefs [Hash]
      #   egress_handler: [ClassName] of handler
      #   scanlog_name: <scan_name>
      #   run_passive_checks: TrueFalse
      #   test_subs: TrueFalse
      #   extensions: Array
      #   evasions: Array

      def initialize(request, prefs)
        raise "No project created!" if Watobo.project.nil?

        @request = request.is_a?(String) ? Watobo::Request.new(request) : request
        @settings = OpenStruct.new prefs
        @chat_list = nil
        @file_list = nil

        file_list_init
        chatlist_init

        @check = Watobo::Plugin::Filescanner::Check.new Watobo.project, @file_list, @settings
        @scanner = Watobo::Scanner3.new(@chat_list, [@check], [], scan_prefs)
      end

      private

      def scan_prefs
        sprefs = Watobo.project.getScanPreferences
      end

      def file_list_init
        # set file_list array as db_file in case it is not a file
        @file_list = [settings.db_file]
        # read file content if db_file is a valid file
        @file_list = File.readlines(settings.db_file) if File.exist?(settings.db_file)
        puts @file_list.length
        # skip comment lines
        @file_list = @file_list.select { |e| !(e.strip =~ /^#/) }
        # remove inline comments
        @file_list = @file_list.map { |e| e.gsub(/#.*/, '') }
        puts @file_list.length
      end


      def chatlist_init
        @chat_list = []
        @chat_list << Watobo::Chat.new(request, [], :id => 0)
        if settings.test_subs
          Watobo::Chats.dirs(request.site, :base_dir => request.dir, :include_subdirs => settings.include_subdirs) do |dir|
            chat = Watobo::Chat.new(request, [], :id => 0)
            chat.request.replaceFileExt('')
            chat.request.setDir(dir)
            @chat_list << chat
          end
        end
      end


    end
  end
end
