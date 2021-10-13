module Watobo #:nodoc: all
  module Plugin
    class NucleiScanner

      extend Forwardable

      def_delegators :@scanner, :sum_progress, :sum_total, :status, :running?, :finished?

      attr :settings, :request, :chat_list, :checks

      # @return [Object] Watobo::Scanner3
      def run(prefs = {})
        scan_prefs = Watobo.project.getScanPreferences
        scan_prefs.update prefs

        if $VERBOSE
          puts "=== FILESCANNER RUN ==="
          puts scan_prefs
          puts '---'
          puts Watobo::Conf::Scanner.to_h
        end

        patterns = get_not_found_pattern(scan_prefs)
        scan_prefs[:custom_error_patterns].concat patterns
        scan_prefs[:custom_error_patterns].uniq!

        if $VERBOSE
          puts '>>> PATTERNS <<<'
          puts scan_prefs[:custom_error_patterns].to_yaml
          puts '--- EOP ---'
        end

        @scanner = Watobo::Scanner3.new(@chat_list, @checks, [], scan_prefs)
        @scanner.run

      end

      # automatically detects pattern for F
      def get_not_found_pattern(prefs)
        sender = Watobo::Session.new(self.object_id, prefs)
        notfound = '404notfound' + SecureRandom.hex(3)
        nfpatterns = []

        @chat_list.each do |chat|
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


          # get plain words of body
          text = test_resp.has_body? ? Nokogiri::HTML(test_resp.body.to_s).text : ''
          words = text.split

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
            pattern = Regexp.quote(wstart) + '.*' + Regexp.quote(wend) + '{1}'
            nfpatterns << pattern
            next
          end

          # seems notfound pattern is not in words,
          # so take 3 words of the middle section
          if words.length >= 3
            mindex = words.length / 2
            wstart = words[mindex - 1]
            wend = words[mindex + 1]
            pattern = Regexp.quote(wstart) + '.*' + Regexp.quote(wend) + '{1}'
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
      #
      # @param templates [Array] template checks
      #
      # @param prefs [Hash]
      #   egress_handler: [ClassName] of handler
      #   scanlog_name: <scan_name>
      #   run_passive_checks: TrueFalse
      #   test_subs: TrueFalse
      #   evasions: Array

      def initialize(request, templates, prefs)
        raise "No project created!" if Watobo.project.nil?

        @request = request.is_a?(String) ? Watobo::Request.new(request) : request
        @settings = OpenStruct.new prefs
        @chat_list = nil
        @file_list = nil
        @checks = templates

        chatlist_init

      end



      private


      def chatlist_init
        @chat_list = []
        @chat_list << Watobo::Chat.new(request, [], :id => 0)
        if settings.test_all_dirs
          Watobo::Chats.dirs(request.site, :base_dir => request.dir) do |dir|
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
