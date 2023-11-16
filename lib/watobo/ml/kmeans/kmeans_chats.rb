require 'kmeans-clusterer'
require "damerau-levenshtein"

module Watobo
  module Ml
    class KmeansChats

      include Watobo::Subscriber

      # Because the number of headers included highly affects the performance as well as the accuracy,
      # we need to reduce the ammount of used headers by this ignore list
      # the overall number of metrics should not be above 200 !!!
      # of course there might be some special responses we might miss
      # TODO: make list configurable from outside, and/or do smarter selection, e.g. ignore only those headers which have similar values
      #
      METRICS_IGNORE_HEADERS = %w(
Date
Connection
Content-Length
Pragma
Strict-Transport-Security
Referrer-Policy
X-XSS-Protection
Cache-Control
X-Frame-Options
Expires
Vary
)

      attr :headers, :status_codes, :body_lens, :metrics, :clusters

      def cluster_by_id(cluster_id)
        @clusters.select { |c| c.id == cluster_id }.first
      end

      def chats_of_cluster(cluster_id, &block)
        coc = []
        c = cluster_by_id cluster_id
        c.points.map { |p| p.id }.each do |id|
          chat = @chats[id]
          yield chat if block_given?
          coc << chat
        end
        coc
      end

      def set_metrics(metrics)
        @metrics = metrics
      end

      def run(prefs = {}, prepare = false)
        dprefs = {
          # num_clusterst default is the number of metrics, which is dynamic because it depends on the number
          # of header/value combinations
          num_clusters: 15,
          runs: 5
        }

        dprefs.update prefs

        notify_progress_init(prepare)

        if prepare
          metrics_preparation
          init_metrics
        end

        kmeans = KMeansClusterer.run dprefs[:num_clusters], metrics, runs: dprefs[:runs]
        notify_inc(steps_kmeans)
        @clusters = kmeans.clusters.sort_by { |c| c.points.length }

        notify_finished
        @clusters
      end

      def initialize(chats)
        @chats = validate_chats(chats)
        @headers = {}
        @status_codes = {}
        @body_lens = {}
        @metrics = nil
        @clusters = nil
        @progress = nil

      end

      private

      def steps_kmeans
        # dummy value for overall calculation
        @chats.length
      end

      def steps_preparation
        sp = 0
        sp += @chats.length # collect_status_codes
        sp += @chats.length # collect_headers
        sp += @chats.length # collect_body_lens
        sp
      end

      def steps_metrics_init
        @chats.length
      end

      def notify_progress_init(prepare)
        progress_total = 0
        if prepare
          progress_total += steps_preparation
          progress_total += steps_metrics_init
        end

        progress_total += steps_kmeans
        p = {
          total: progress_total,
          progress: 0,
          status: :running
        }

        @progress = p
        notify(:progress, p)
      end

      def notify_inc(inc)
        @progress_block_size ||= 0
        @progress_block_size += 1
        @progress[:progress] += 1
        if @progress_block_size > 100
          notify(:progress, @progress)
          @progress_block_size = 0
        end
      end

      def notify_finished
        @progress[:status] = :finished
        notify(:progress, @progress)
      end

      def metrics_preparation
        # start = Time.now.to_i
        collect_status_codes
        # duration = Time.now.to_i - start
        # puts "Collecting Status-Code: #{duration} sec"

        # start = Time.now.to_i
        collect_headers
        # duration = Time.now.to_i - start
        # puts "Collecting Headers: #{duration} sec"

        # start = Time.now.to_i
        collect_body_lens
        # duration = Time.now.to_i - start
        # puts "Collecting Body-Lens: #{duration} sec"

        collect_condensed_bodies

      end

      # @param chat [Watobo::Chat]
      #
      # Metrics Array
      # [0] - status-code * 10
      # [1] - body-length or condensed body length
      # [2] - condensed body diff (levensthein)
      # [3..n] - headers
      def chat_metrics(chat, index = -1)
        @differ ||= DamerauLevenshtein

        begin
          metrics = []
          metrics << chat.response.status_code.to_i * 10

          if index >= 0 && @condensed_bodies[index]
            metrics << @condensed_bodies[index].length * 10

            dist = @differ.distance @longest_condensed_body, @condensed_bodies[index]

            metrics << dist * 100

          else
            metrics << chat.response.body.to_s.length
          end

          # for generating the header metrics we first make a shallow copy of the original headers
          # this copy is used for marking (set to nil) the matched headers
          # afterwards all header metrics coresponding to nil are set to their values
          # all others will be 0
          headers_copy = @headers.clone

          # metrics.concat @headers.keys.map { |hk| chat.response.headers.select { |rh| rh.strip =~ /#{Regexp.quote(hk.strip)}/i }.length > 0 ? 1000 : 0 }
          # metrics.concat @headers.keys.map { |hk| chat.response.headers(Regexp.quote(hk.strip)).length > 0 ? 1000 : 0 }
          chat.response.headers.each do |h|
            # we have to use condensed headers here, if we generated the collection too
            header = condense_header(h)
            headers_copy[header] = nil if !!headers_copy[header]
          end

          metrics.concat headers_copy.keys.map { |hk| hk ? 0 : 1000 }

          return metrics
        rescue => bang
          puts bang
          puts bang.backtrace
          # binding.pry
        end
        nil
      end

      def init_metrics
        @metrics = []
        @chats.each_with_index do |chat, i|
          notify_inc 1
          @metrics << chat_metrics(chat, i)
        end
      end

      def validate_chats(chats)
        vchats = []
        chats.each do |chat|
          next unless chat.response.respond_to?(:headers)
          next if chat.response.headers('Server').first =~ /watobo/i
          vchats << chat
        end
        vchats
      end

      def collect_headers
        @chats.each do |chat|
          notify_inc 1
          chat.response.headers.each do |h|
            # experimental use of condensed strings
            header = condense_header(h)
            next if METRICS_IGNORE_HEADERS.select { |ignore| header =~ /^#{ignore}/i }.length > 0
            @headers[header] ||= 0
            @headers[header] += 1

          end
        end

      end

      # condense_header "AAAA: alsdjkflkajslfkjljwioerowielksjdlfkjalaadlkajsdlf"
      # => "AAAA: adefijklorsw"
      def condense_header(h)
        i = h.index(':')
        name = h[0..i]
        val = h[i + 1..-1]
        cval = val.chars.uniq.sort.join.strip
        "#{name} #{cval}"
      end

      def collect_status_codes
        @chats.each do |chat|
          notify_inc 1
          code = chat.response.status_code.to_i
          @status_codes[code] ||= 0
          @status_codes[code] += 1
        end

      end

      def collect_condensed_bodies
        @condensed_bodies = []
        @chats.each do |chat|
          next unless chat.response.has_body?
          notify_inc 1
          if chat.response.is_binary?
            cb = Digest::MD5.hexdigest(chat.response.body)
          else
            cb = chat.response.body.to_s.chars.uniq.sort.join.strip
          end
          #@condensed_bodies << cb.force_encoding('UTF-8').encode('UTF-8')
          @condensed_bodies << cb.force_encoding('UTF-8').encode('UTF-8', :invalid => :replace, :replace => '')

        end

        # @longest_condensed_body is used as the baseline for levensthein diffing
        @longest_condensed_body = @condensed_bodies.sort_by { |b| b.length }.reverse.first
      end

      def collect_body_lens
        @chats.each do |chat|
          notify_inc 1
          len = chat.response.body.to_s.length.to_i
          @body_lens[len] ||= 0
          @body_lens[len] += 1
        end
      end

    end
  end

end