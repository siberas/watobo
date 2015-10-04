# @private 
module Watobo#:nodoc: all
  module Interceptor
    class Filter

      attr :match_type, :flags, :pattern
      def name
        self.class.to_s.gsub(/.*::/,'')
      end

      def negated?
        @negate
      end

      def negate=(state)
        @negate = state
      end

      def match?(item, flags)
       
        return !check?(item, flags) if @negate == true
        return check?(item, flags)
      end

      def initialize(pattern, prefs={})
        @flags = prefs.has_key?(:flags) ? prefs[:flags] : []
        @match_type = prefs.has_key?(:match_type) ? prefs[:match_type] : :match
        @negate = ( @match_type.to_s =~ /^not/ )
        @pattern = pattern
      end

    end
    
    class FlagFilter < Filter
      def check?(item, flags=nil)
        @flags.each do |f|
          return false unless flags.include? f
        end
        return true
      end
    end

    class UrlFilter < Filter
      def check?(item, flags=nil)
        return false unless item.respond_to? :url
        return true if @pattern.empty?
        match = false
        match = true if item.url =~ /#{@pattern}/i
        match
      end

    end

    class HttpParmsFilter < Filter
      def check?(item, flags=nil)
        return false unless item.respond_to? :parms
        return true if @pattern.empty?
        match = request.parms.find {|x| x =~ /#{@pattern}/ }
        match = !match_parms.nil?
        match
      end
    end

    class MethodFilter < Filter
      def check?(item, flags=nil)
        return false unless item.respond_to? :method
        return true if @pattern.empty?
        match = false
        match = true if item.method =~ /#{@pattern}/i
        match
      end

    end

    class StatusFilter < Filter
      def check?(item, flags=nil)
        return false unless item.respond_to? :method
        return true if @pattern.empty?
        match = false
        match = true if item.status =~ /#{@pattern}/i
        match
      end

    end

    class FilterChain
      def match?(item, flags=nil)
        @filters.each do |f|
          return false unless f.match?( item, flags )
        end
        true
      end

      def add_filter(filter)
        @filters << filter if filter.respond_to? :match?

      end

      def remove_filter(pos)

      end
      
      def set_filters(filter)
        @filters = filter
      end
      
      def list
        @filters
      end

      def clear
        @filters.clear
      end

      def initialize
        @filters = []
      end
    end

    class RequestFilter
      def match?(request)
        match_url = true
        # puts @request_filter_settings.to_yaml

        if url_filter != ''
          match_url = false
          if request.url.to_s =~ /#{url_filter}/i
          match_url = true
          end
          if negate_url_filter == true
          match_url = ( match_url == true ) ? false : true
          end
        end

        return false if match_url == false

        match_method = true

        if method_filter != ''
          match_method = false
          if request.method =~ /#{method_filter}/i
          match_method = true
          end

          if negate_method_filter == true
          match_method = ( match_method == true ) ? false : true
          end
        end

        return false if match_method == false

        match_ftype = true
        ftype_filter = file_type_filter
        if ftype_filter != ''
          match_ftype = false
          if request.doctype != '' and request.doctype =~ /#{ftype_filter}/i
          match_ftype = true
          end
          if negate_file_type_filter == true
          match_ftype = ( match_ftype == true ) ? false : true
          end
        end
        return false if match_ftype == false

        match_parms = true
        # parms_filter = @request_filter_settings[:parms_filter]
        if parms_filter != ''
          # puts "!PARMS FILTER: #{parms_filter}"
          match_parms = false
          puts request.parms
          match_parms = request.parms.find {|x| x =~ /#{parms_filter}/ }
          match_parms = ( match_parms.nil? ) ? false : true
          if negate_parms_filter == true
          match_parms = ( match_parms == true ) ? false : true
          end
        end
        return false if match_parms == false

        true
      end

      def initialize(parms)
        @settings = {
          :site_in_scope => false,
          :method_filter => '(get|post|put)',
          :negate_method_filter => false,
          :negate_url_filter => false,
          :url_filter => '',
          :file_type_filter => '(jpg|gif|png|jpeg|bmp)',
          :negate_file_type_filter => true,

          :parms_filter => '',
          :negate_parms_filter => false
          #:regex_location => 0, # TODO: HEADER_LOCATION, BODY_LOCATION, ALL

        }
        [ :site_in_scope, :method_filter,:negate_method_filter, :negate_url_filter,:url_filter, :file_type_filter,:negate_file_type_filter,:parms_filter,:negate_parms_filter].each do |k|
          @settings[k] = parms[k]
        end
      #:regex_location => 0, # TODO: HEADER_LOCATION, BODY_LOCATION, ALL

      end

      private

      def method_missing(name, *args, &block)
        # puts "* instance method missing (#{name})"
        @settings.has_key? name.to_sym || super
        @settings[name.to_sym]
      end
    end

  end
end

if $0 == __FILE__
  inc_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..","lib"))
  $: << inc_path

  require 'watobo'

  r = Watobo.create_request("www.siberas.com")
  puts r
  fc = Watobo::Interceptor::FilterChain.new
  fc.add_filter Watobo::Interceptor::UrlFilter.new("(www|\.de)")
  fc.add_filter Watobo::Interceptor::MethodFilter.new("GeT")
  m = fc.match? r
  puts m

  r = Watobo.create_request("sec.siberas.com")
  r.method = "Post"
  puts r

  m = fc.match? r
  puts m

end