module Watobo
  module Headless
    class Spider
      class Trigger

        attr :script, :src, :tag_name, :html

        def to_s
          "[#{fingerprint}] #{src}: (#{tag_name}) #{script} * #{html}"
        end

        def fingerprint(opts={})
          key = [ src, html ]
          Digest::MD5.hexdigest key.join(':')
        end



        def initialize(url, tag_name, html, script)
          @src = url
          @tag_name = tag_name
          @script = script
          @html = html

        end
      end
    end
  end
end