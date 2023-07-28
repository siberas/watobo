module Watobo::EvasionHandlers
  class ParmExtensions < EvasionHandlerBase

    prio 1

    EVASION_PARAMS = %w( y=x.png debug=true mode=debug layout=debug y=x.jpg y=x.bmp y=x.jpeg y=x.svg )

    def run(request, &block)
      puts "! run evasion #{self}" if $DEBUG
      params = EVASION_PARAMS.map { |p|
        n, v = p.split('=')
        prefs = {name: n, value: v}
        Watobo::UrlParameter.new(prefs)
      }
      params.each do |p|
        test = request.clone
        test.set p
        yield test
      end
    end
  end
end
