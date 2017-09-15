# @private 
module Watobo #:nodoc: all
  module HTTP
    class Url
      def to_s
        @root.url_string
      end

      def set(parm)
        if has_parm?(parm.name)
          @root.replace_get_parm(parm.name, parm.value)
        else
          @root.add_get_parm(parm.name, parm.value)
        end
      end

      def has_parm?(parm_name)
        @root.get_parm_names do |pn|
          return true if pn == parm_name
        end
        false
      end

      def parameters(&block)
        parms = []
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