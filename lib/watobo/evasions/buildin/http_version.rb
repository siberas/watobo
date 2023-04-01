module Watobo::EvasionHandler
  class HTTPVersion

    INJECTIONS = %w( 4.0 /1.1 * )

    def run(request, &block)
      INJECTIONS.each do |v|
        test = request.clone
        test.version = v
        yield test
      end
    end
  end
end