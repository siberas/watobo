require 'kmeans-clusterer'

module Watobo
  module Ml
    class KmeansChats

      # Because the number of headers included highly affects the performance as well as the accuracy,
      # we need to reduce the ammount of used headers by this ignore list
      # the overall number of metrics should not be above 200 !!!
      # of course there might be some special responses we might miss
      # TODO: make list configurable from outside, and/or do smarter selection, e.g. ignore only those headers which have similar values
      #
      METRICS_IGNORE_HEADERS = %w(
                  Date Connection Content-Length Set-Cookie Pragma
                  Strict-Transport-Security Referrer-Policy X-XSS-Protection
                  Location
                  Cache-Control X-Frame-Options Expires Vary
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


      def run(prefs = {})
        dprefs = {
            # num_clusterst default is the number of metrics, which is dynamic because it depends on the number
            # of header/value combinations
            num_clusters: 15,
            runs: 5,
            # filter clusters by their maximum number of points
            max_points: -1
        }

        dprefs.update prefs

        kmeans = KMeansClusterer.run dprefs[:num_clusters], metrics, runs: dprefs[:runs]
        clusters = kmeans.clusters.sort_by { |c| c.points.length }
        @clusters = dprefs[:max_points] > 0 ? clusters.select { |c| c.points.length < dprefs[:max_points] } : clusters

        @clusters
      end

      def initialize(chats)
        @chats = validate_chats(chats)
        @headers = {}
        @status_codes = {}
        @body_lens = {}
        @metrics = nil
        @clusters = nil

        start = Time.now.to_i
        collect_status_codes
        duration = Time.now.to_i - start
        puts "Collecting Status-Code: #{duration} sec"

        start = Time.now.to_i
        collect_headers
        duration = Time.now.to_i - start
        puts "Collecting Headers: #{duration} sec"

        start = Time.now.to_i
        collect_body_lens
        duration = Time.now.to_i - start
        puts "Collecting Body-Lens: #{duration} sec"

        start = Time.now.to_i
        init_metrics
        duration = Time.now.to_i - start
        puts "Creating Metrics: #{duration} sec"

      end

      private

      # @param chat [Watobo::Chat]
      #
      # Metrics Array
      # [0] - status-code * 10
      # [1] - body-length
      # [2..n] - headers
      def chat_metrics(chat)
        begin
        metrics = []
        metrics << chat.response.status_code.to_i * 10
        metrics << chat.response.body.to_s.length
        headers_copy = @headers.clone

          #metrics.concat @headers.keys.map { |hk| chat.response.headers.select { |rh| rh.strip =~ /#{Regexp.quote(hk.strip)}/i }.length > 0 ? 1000 : 0 }
          #metrics.concat @headers.keys.map { |hk| chat.response.headers(Regexp.quote(hk.strip)).length > 0 ? 1000 : 0 }
        chat.response.headers.each do |header|
          headers_copy[header] = nil if !!headers_copy[header]
        end

        metrics.concat headers_copy.keys.map { |hk| hk ? 0 : 1000 }

        return metrics
        rescue => bang
          puts bang
          puts bang.backtrace
        end
        nil
      end

      def init_metrics
        @metrics = []
        @chats.each do |chat|
          @metrics << chat_metrics(chat)
        end
      end

      def validate_chats(chats)
        vchats = []
        chats.each do |chat|
          next if chat.response.headers('Server').first =~ /watobo/i
          vchats << chat
        end
        vchats
      end

      def collect_headers
        @chats.each do |chat|
          chat.response.headers.each do |h|
            header = h.strip
            next if METRICS_IGNORE_HEADERS.select { |ignore| header =~ /^#{ignore}/i }.length > 0
            @headers[header] ||= 0
            @headers[header] += 1

          end
        end

      end

      def collect_status_codes
        @chats.each do |chat|
          code = chat.response.status_code.to_i
          @status_codes[code] ||= 0
          @status_codes[code] += 1
        end

      end

      def collect_body_lens
        @chats.each do |chat|
          len = chat.response.body.to_s.length.to_i
          @body_lens[len] ||= 0
          @body_lens[len] += 1
        end
      end


    end
  end

end