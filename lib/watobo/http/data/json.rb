# @private 
module Watobo#:nodoc: all
  module HTTPData
   
    class JSONData < Base
      
      def to_s
        s = @root.body.nil? ? "" : @root.body
      end
      
      def set(parm)
         parms = JSON.parse(@root.body.to_s)
         parms[parm.name] = parm.value
         @root.set_body parms.to_json
      end

      def has_parm?(parm_name)
        parms = JSON.parse(@root.body.to_s)
        return true if parms.has_key? parm_name
        false
      end

      def parameters(&block)
        parms = []
        json_str = @root.body.to_s
        
        begin
        JSON.parse(json_str).each do |k,v|
          val = v.is_a?(String) ? v : v.to_s
          parms << Watobo::JSONParameter.new( :name => k, :value => val )
        end
        rescue => bang
          puts "! could not parse JSON parameters !"
          puts @root.headers
          puts json_str.gsub(/[^[:print:]]/, '.')
        end
        parms
      end

      def initialize(root)
        super root

      end
    end

  end

end