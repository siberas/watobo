module Watobo::EvasionHandlers
  class AppendSlash < EvasionHandlerBase

    prio 4

    def run(request, &block)
      test = request.clone
      test.path = test.path_ext

      yield test
    end
  end
end