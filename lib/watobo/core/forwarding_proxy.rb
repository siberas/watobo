# @private
module Watobo#:nodoc: all
  module ForwardingProxy

    
    def self.get(site=nil)
      begin
        fp = Watobo::Conf::ForwardingProxy.to_h
        
        if site.nil?
          return nil unless fp.has_key? :default_proxy
          return nil if fp[:default_proxy].empty?
          name = fp[:default_proxy]
          proxy = fp[:name]
          return Watobo::Proxy.new(proxy)
        end
        
        fp.each do |pn, ps|
          # ignore old style proxy 
          next unless ps.respond_to? :has_key?
          next unless ps.has_key? :enabled
          next unless ps[:enabled]
          
          if ps.has_key? :target_pattern
            pat = ps[:target_pattern]
            pat = ".*" if pat == "*"
            if site =~ /#{ps[:target_pattern]}/
              proxy = Watobo::Proxy.new(ps)
              return proxy
            end
          end
        end        

      rescue => bang
        puts bang
        puts bang.backtrace
        puts fp
      end
      return nil
    end
  end
end