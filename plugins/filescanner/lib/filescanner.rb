module Watobo #:nodoc: all
  module Plugin
    class Filescanner

      STATUS_IDLE = 0x00
      STATUS_RUNNING = 0x01
      STATUS_FINISHED = 0x02
      # extend Forwardable

      # def_delegators :@scanner, :sum_progress, :sum_total, :status, :running?, :finished?

      attr :settings, :request, :file_list, :chat_list

      @@lock = Mutex.new

      def sum_progress
        return 0 if @scanner.nil?
        @scanner.sum_progress
      end

      def sum_total
        return 0 if @scanner.nil?
        @scanner.sum_total
      end

      def status
        return 0 if @scanner.nil?
        @scanner.status
      end

      def running?
        @status == STATUS_RUNNING
      end

      def finished?
        @status == STATUS_FINISHED
      end

      # @return [Object] Watobo::Scanner3
      def run(prefs = {})
        @status = STATUS_RUNNING
        scan_prefs = Watobo.project.getScanPreferences
        scan_prefs.update prefs

        if $VERBOSE
          puts "=== FILESCANNER RUN ==="
          puts scan_prefs
          puts '---'
          puts Watobo::Conf::Scanner.to_h
        end

        Thread.new {
          @@lock.synchronize {
            patterns = get_not_found_pattern(scan_prefs)
            scan_prefs[:custom_error_patterns].concat patterns
            scan_prefs[:custom_error_patterns].uniq!

            if $VERBOSE || $DEBUG
              puts '>>> PATTERNS <<<'
              puts scan_prefs[:custom_error_patterns].to_yaml
              puts '--- EOP ---'
            end
          }

        }

        # sleep a bit to ensure that thread for get_not_found_patterns gets @@lock first
        sleep 1

        Thread.new {
          @@lock.synchronize {
            @check = Watobo::Plugin::Filescanner::Check.new Watobo.project, @file_list, scan_prefs
            @scanner = Watobo::Scanner3.new(@chat_list, [@check], [], scan_prefs)
            @scanner.subscribe(:scanner_finished){
              @status = STATUS_FINISHED
            }
            @scanner.run
          }
        }
        @scanner
      end

      # automatically detects pattern for F
      def get_not_found_pattern(prefs)
        sender = Watobo::Session.new(self.object_id, prefs)

        nfpatterns = []

        @chat_list.each do |chat|
          notfound = '404notfound' + SecureRandom.hex(3)
          request = chat.copyRequest
          request.replaceFileExt(notfound)

          test_req, test_resp = sender.doRequest(request)
          if $VERBOSE
            puts "REQUEST >>>"
            puts test_req
            puts "RESPONSE <<<"
            puts test_resp
            puts '---'
          end
          status = test_resp.status
          # skip if status is 4xx, because this will be recognized by fileExists?
          next if status =~ /^4/

          # check for a redirect
          if status =~ /^30/
            location = test_resp.headers("Location:").first
            nfpatterns << Regexp.quote(location.gsub(/#{notfound}.*/, '').strip)
            next
          end


          next unless test_resp.has_body?
          # get plain words of body
          text = Nokogiri::HTML(test_resp.body.to_s).text
          words = text.split
          if words.length < 3
            words = test_resp.body.to_s.split
          end

          # check if words contain not found
          nfi = words.index { |w| w =~ /#{notfound}/i }
          if nfi
            if nfi > 0
              wstart = words[nfi - 1]
              wend = words[nfi + 1]
            else
              wstart = words[1]
              wend = words[3]
            end
            pattern = Regexp.quote(wstart) + '.*' + Regexp.quote(wend)
            nfpatterns << pattern
            next
          end

          # seems notfound pattern is not in words,
          # so take 3 words of the middle section
          if words.length >= 3
            mindex = words.length / 2
            wstart = words[mindex - 1]
            wend = words[mindex + 1]
            pattern = Regexp.quote(wstart) + '.*' + Regexp.quote(wend)
            nfpatterns << pattern
            next
          end
        end

        nfpatterns
      end

      def stop
        # stop scanner
        @scanner.stop if @scanner.respond_to? :stop
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
      #   db_file: [String] url-path to check or filename of db (list of url-paths line-separated)
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
        @status =

        file_list_init
        chatlist_init


      end


      private

      #def scan_prefs
      #  sprefs = Watobo.project.getScanPreferences
      #end

      def file_list_init
        # set file_list array as db_file in case it is not a file
        @file_list = [settings.db_file]
        # read file content if db_file is a valid file
        @file_list = File.readlines(settings.db_file) if File.exist?(settings.db_file)
        # skip comment lines
        @file_list = @file_list.select { |e| !(e.strip =~ /^#/) }
        # remove inline comments
        @file_list = @file_list.map { |e| e.gsub(/#.*/, '') }
      end


      def chatlist_init
        @chat_list = []
        @chat_list << Watobo::Chat.new(request, [], :id => 0)
        if settings.test_all_dirs
          Watobo::Chats.dirs(request.site, :base_dir => request.dir).each do |dir|
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
