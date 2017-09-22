# @private
module Watobo#:nodoc: all
  module HTTP
    class Cookies
      def to_s
        s = []
        @cookies.each_value do |v|
          s << "#{v.name}=#{v.value}"
        end
        s.join("; ")
      end

      def inspect
        self.to_a
      end

      def empty?
        @cookies.empty?
      end

      def clear
        @cookies.clear
        @root.removeCookies
      end

      def to_a
        cookies = []
        raw_cookies do |c|
          cookies << Watobo::Cookie.new(c)
        end
        cookies
      end

      def each(&block)
        @cookies.each_value do |cookie|
          yield cookie if block_given?
        end
      end

      def set(parm)
        @cookies[parm.name.to_sym] = parm
        @root.set_header("Cookie", self.to_s)
      end

      def has_parm?(parm_name)
        false
      end

      #def

      def parameters(&block)
        params = []
        raw_cookies do |cprefs|
          cookie = Watobo::CookieParameter.new(cprefs)
          yield cookie if block_given?
          params << cookie

        end
        params
      end

      def initialize(root)
        @root = root
        @cookies = {}

        init_cookies

      end

      private

      def init_cookies
        raw_cookies do |rc|
          if rc.has_key? :name
            @cookies[rc[:name].to_sym] = Watobo::Cookie.new(rc)
          end
        end
      end

      def raw_cookies(&block)
        rcs = []
        @root.headers.each do |line|
          begin
            if line =~ /^(Set\-)?Cookie2?: (.*)/i then
              clist = $2.split(";")
              cookie_prefs = { :secure => false, :http_only => false }
              cookie_prefs[:secure] = true if line =~ /secure/i
              cookie_prefs[:http_only] = true if line =~ /httponly/i

              clist.each do |c|
                c.strip!
                i = c.index("=")

                # skip cookie options
                next if i.nil?

                name = c[0..i-1]
                value = i < c.length ? c[i+1..-1] : ""
                cookie_prefs[:name] = name.strip
                cookie_prefs[:value] = value.strip
                #cookie = Watobo::CookieParameter.new(cookie_prefs)
                yield cookie_prefs if block_given?
                rcs << cookie_prefs
              end
            end
          rescue => bang
            puts bang
            puts bang.backtrace
            puts line
          end
        end

        return rcs

      end

      module Mixin
        def cookies
          @cookies ||= Cookies.new(self)
        end
      end
    end
  end
end