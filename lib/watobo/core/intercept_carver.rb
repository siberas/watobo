# @private 
module Watobo#:nodoc: all
  module Interceptor
    class CarverRule
      def action_name
        action.to_s
      end

      def location_name
        location.to_s
      end

      def pattern_name
        Regexp.quote pattern
      end

      def filter_name
        # return "NA" if filter.nil?
        return filter.class.to_s
      end
      
      def set_filter(filter_chain)
        puts "* set filter_chain"
        puts filter_chain.class
        @settings[:filter] = filter_chain
      end
      
      def filters
        return [] unless filter.respond_to? :list
        filter.list
      end

      def content_name
        content
      end
      
      
      # rewrite options
      # item
      # location
      # pattern
      # content
      def rewrite(item, l, p, c)
        res = false
        case l
        when :replace_all
          if File.exist? c
            begin
             item.replace Watobo::Utils.string2response(File.open(c,"rb").read)              
            rescue => bang
              puts bang
              puts bang.backtrace
            end
          else
            puts "Could not find file > #{c}"
          end
          
        when :body
          if item.respond_to? :body
            if p.upcase == :ALL
            res = item.replace_body(c)
            else
              puts "* rewrite body ..."
            res = item.rewrite_body(p,c)
            end
          end
        when :http_parm
          1
        when :cookie
          1
        when :url
          if item.respond_to? :url
            item.first.gsub!(/#{p}/, c)
          end
        when :header
          puts "REPLACE HEADER"
          item.each_with_index do |line, index|
            if line =~ /#{p}/
              item[index] = "#{c.strip}\r\n"
            end
            break if line.strip.empty?
          end
          res = item  
        end
        res
      end

      def apply(item, flags)
        begin
          unless filter.nil?
          return false unless filter.match?(item, flags)
          end
          res = case action
          when :flag
            puts "set flag >> #{content} (#{content.class})"
            flags << :request
            true
          when :inject
            inject_content(item, location, pattern, content)
          when :rewrite
            puts "REWRITE"
            puts "Location: #{location}"
            puts "Pattern: #{pattern}"
           # puts "Content: #{content}"
            rewrite(item, location, pattern, content)
          else
            true
          end
          return res
        rescue => bang
          puts bang
          puts bang.backtrace
        end
      end

      def initialize(parms)
        @settings = Hash.new
        [:action, :location, :pattern, :content, :filter].each do |k|
          @settings[k] = parms[k]
        end

      end

      private

      def method_missing(name, *args, &block)
        # puts "* instance method missing (#{name})"
        @settings.has_key? name.to_sym || super
        @settings[name.to_sym]
      end
    end

    class Carver
      @rules = []
      
      def self.rules
        @rules
      end      
      
      def self.shape(response, flags)
       @rules.each do |r|
         res = r.apply( response, flags )
         puts "[rewrite] #{r.action_name} (#{r.action.class}) >> #{res.class}"
       end
      end
      
      def self.set_carving_rules(rules)
        @rules = rules
      end

      def self.add_rule(rule)
        @rules << rule if rule.respond_to? :apply
      end

      def self.clear_rules
        @rules.clear
      end      
    end
    
    class RequestCarver < Carver
       @rules = []      
    end
    
    class ResponseCarver < Carver
       @rules = []    
    end
  end
end