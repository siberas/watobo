module Watobo
  module Headless
    class Spider
      class Href

        attr :href, :src

        def to_s
          @href
        end

        def fingerprint(opts={})
            o = {:clear_values => true}
            o.update opts

            uri = cleanup_uri(href)

            query_sorted = ""
            query_sorted = uri.query.split("&").sort.join("&") unless uri.query.nil?
            query_sorted.gsub!(/=[^&]*/, '=') if o[:clear_values] == true
            key = []
            key << uri.scheme
            key << uri.host
            key << uri.port
            key << uri.path
            key << query_sorted


            Digest::MD5.hexdigest key.join(':')
        end

        def cleanup_uri(obj)
          uri = nil
          uri = obj.uri if obj.respond_to? :uri
          uri = URI.parse(obj) if obj.is_a? String
          uri = obj if obj.is_a? URI::HTTP
          uri
        end

        # returns url without parameter values
        def without_values

        end

        # return query params with value
        def query_params

        end

        # checks if hostnames are the same
        def match_host?(host)
          uri = URI.parse @href
          uri.fragment = nil
          url = uri.to_s
          url.match? /^.{1,5}:\/\/[^[:\/]]*#{host}/
        end

        # check if domain name is the same. ignore subdomains
        # e.g. www.domain.at will match api.domain.at
        def match_domain?(host)

        end

        def initialize(url, input)
          @src = url

          @href = input.respond_to?(:attribute) ?  input.attribute('href') : input

        end
      end
    end
  end
end