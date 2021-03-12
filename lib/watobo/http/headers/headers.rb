# @private
module Watobo #:nodoc: all
  module HTTP
    class Headers
      SKIP_HEADERS = %w( Connection Content-Length ).map{|m| m.upcase }
      def to_s
        s = []
        @headers.each_value do |v|
          s << "#{v.name}=#{v.value}"
        end
        s.join("\n")
      end

      def inspect
        self.to_a
      end

      def empty?
        @headers.empty?
      end

      def clear
        @headers.clear
      end

      def to_a
        @headers.values
      end

      def each(&block)
        @headers.each_value do |h|
          yield h if block_given?
        end
      end

      def set(param)
        @root.set_header(param.name, param.value)
      end

      def has_parm?(parm_name)
        false
      end

      #def

      def parameters(&block)
        params = []
        @headers.each_value do | h |
        yield h if block_given?
        params << h
      end
      params
      end

      def initialize(root)
        @root = root
        @headers = {}

        init_header_params

      end

      private

      def init_header_params
        raw_headers = @root.headers
        raw_headers.shift

        raw_headers.each do |line|
          begin
            # skip cookies because they are handled by Cookies class.
            next if line =~ /^(Set\-)?Cookie2?: (.*)/i
            i = line.index(":")

            next if i.nil?

            name = line[0..i - 1]
            next if SKIP_HEADERS.include?( name.upcase )
            value = i < line.length ? line[i + 1..-1] : ""
            header_prefs = {}
            header_prefs[:name] = name.strip
            header_prefs[:value] = value.strip

            @headers[name] = Watobo::HeaderParameter.new(header_prefs)

          end
        end

      end


      module Mixin
        def headers
          @headers ||= Headers.new(self)
        end
      end
    end
  end
end