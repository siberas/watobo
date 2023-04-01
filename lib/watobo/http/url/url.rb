# @private 
module Watobo #:nodoc: all
  module HTTP
    class Url

      def to_str
        @root.url_string
      end

      def to_s
        @root.url_string
      end

      def to_uri
        # we need some cleanup before URI.parsing
        URI.parse(@root.url_string.gsub(/[^a-zA-Z0-9\/;\-:\.]/) do |m|
                URI.encode_www_form_component(m)
        end
        )
      end

      def set(parm)
        if has_parm?(parm.name)
          @root.replace_get_parm(parm.name, parm.value)
        else
          @root.add_get_parm(parm.name, parm.value)
        end
      end

      def clear
        @root.removeUrlParms
      end

      def has_parm?(parm_name)
        @root.get_parm_names do |pn|
          return true if pn == parm_name
        end
        false
      end

      def parameters(&block)
        parms = []
       # binding.pry
        @root.get_parms.each do |p|
          p.strip!
          i = p.index("=")
          name = p[0..i-1]
          val = i < p.length ? p[i+1..-1] : ""
          parms << Watobo::UrlParameter.new(:name => name, :value => val)
        end
        parms
      end

      def initialize(root)
        @root = root

      end
    end
  end
end