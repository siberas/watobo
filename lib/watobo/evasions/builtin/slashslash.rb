module Watobo::EvasionHandlers
  class SlashSlash < EvasionHandlerBase

    prio 4

    def run(request, &block)
      test = request.clone
      test.path = test.path_ext.split('/').join('//')
      yield test

      # insert ';' between all path elements
      test = request.clone
      test.path = test.path_ext.split('/').join('///')
      yield test
    end
  end
end