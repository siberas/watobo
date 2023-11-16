module Watobo::EvasionHandlers
  class PathExtensions < EvasionHandlerBase

    # query extension will only be applied if no query is present in the original request
    PATH_EXTENSIONS = %w( WSDL wsdl debug %0d%0a ??? )

    prio 3

    def run(request, &block)
      return if request.query.empty?

      PATH_EXTENSIONS.each do |v|
        test = request.clone
        test.replaceQuery(v)
        yield test
      end
    end
  end
end