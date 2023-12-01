module Watobo::EvasionHandlers
  # Authorization Bypass based on empty or malformed Autorization Header
  #
  class AuthHeader < EvasionHandlerBase

    prio 3

    AUTH_TYPES = %w( null nil 0 false true debug authorized )
    AUTH_TYPES.unshift ''

    AUTH_VALUES = [
      '',
      'valid',
      'authorized',
      'false',
      'true'
    ]

    def run(request, &block)
      AUTH_TYPES.each do |at|

        unless at.empty?
          AUTH_VALUES.each do |av|
            test = request.clone
            test.set_header "Authorization: #{at} #{av}"
            yield test
          end
        else
          test = request.clone
          test.set_header "Authorization: "
          yield test
        end

      end

    end
  end

end