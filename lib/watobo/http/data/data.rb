# @private 
module Watobo#:nodoc: all
  module HTTPData
    class Base
      def to_s
        s = @root.body.nil? ? "" : @root.body
      end

      def initialize(root)
        @root = root
      end
    end

    class WWW_Form < Base
      def set(parm)
        if has_parm?(parm.name)
        @root.replace_post_parm(parm.name, parm.value)
        else
        @root.add_post_parm(parm.name, parm.value)
        end
      end

      def has_parm?(parm_name)
        @root.post_parm_names do |pn|
          return true if pn == parm_name
        end
        false
      end

      def parameters(&block)
        parms = []
        @root.post_parms.each do |p|
          nvsi = p.index("=")
          unless nvsi.nil?
            name = nvsi > 0 ? p[0..nvsi-1] : ""
            val = nvsi < (p.length-1) ? p[nvsi+1..-1] : ""
            parms << Watobo::WWWFormParameter.new( :name => name, :value => val )
          end
        end
        parms
      end

      def initialize(root)
        super root

      end
    end

  end

end