module Watobo::EvasionHandlers
  class UrlExtensions < EvasionHandlerBase

    prio 2

    def run(request, &block)
      puts "! run evasion #{self}" if $DEBUG
      # insert /. between all path elements
      #binding.pry
      test = request.clone
      test.path = test.path.split('/').join('/./')
      yield test

      # insert ';' between all path elements
      test = request.clone
      test.path = test.path.split('/').join(';/')
      yield test

      # insert ';' between every single path elements
      test = request.clone
      pes = test.path.split('/')


      pes.length.times do |i|
        first = pes[0..i].join('/')
        last = pes[i+1..-1].join('/')
        test.path = first + ';/' + last
        test = request.clone
      end


    end
  end
end