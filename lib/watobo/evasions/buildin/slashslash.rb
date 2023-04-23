module Watobo::EvasionHandler
  class SlashSlash

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