module Watobo
  class CookieStoreClazz

    def get_cookies(request)
      return [] unless @cookies[request.origin]
      @cookies[request.origin].values.select{|c| c.path == '/' || request.path.match?(/#{c.path}/i) }
    end
    def initialize
      @cookies = {}
    end

    def update(request, response)
      set_cookies = response.headers.select{|h| h.match?(/^Set-Cookie/i) }
      cookies = set_cookies.map{|c| Watobo::Cookie.new(c)}

      @cookies[request.origin] ||= {}
      cookies.each do |c|
        @cookies[request.origin][c.name] = c
      end
    end


  end

  CookieStore = CookieStoreClazz.new
end