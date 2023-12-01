module Watobo::EvasionHandlers
  class HttpMethodOverride < EvasionHandlerBase
    # https://javadoc.io/static/org.glassfish.jersey.bundles/jaxrs-ri/3.0.3/org/glassfish/jersey/server/filter/HttpMethodOverrideFilter.html
    # https://www.sidechannel.blog/en/http-method-override-what-it-is-and-how-a-pentester-can-use-it/
    # https://www.ibm.com/docs/en/odm/8.10?topic=methods-overriding-security-restrictions-http
    #
    OVERRIDE_HEADERS = %w(
X-HTTP-Method-Override
X-Http-Method-Override
X-HTTP-Method
X-Http-Method
X-Method-Override
    )

    OVERRIDE_URL_PARMS = %w(
x-method-override
x-http-method-override
_method
    )

    # innocent methods are http methods used to get past the first authentication filter.
    INNOCENT_METHODS = %w( OPTIONS HEAD TRACE GET CONNECT )

    OVERRIDE_METHODS = %w( XXX GET PUT POST HEAD TRACE TRACK )

    prio 3

    def run(request, &block)
      test_methods = INNOCENT_METHODS.dup
      test_methods << request.method

      test_methods.each do |tm|
        OVERRIDE_HEADERS.each do |header|
          OVERRIDE_METHODS.each do |ovr|
            next if ovr == tm
            test = request.clone
            test.method = tm
            test.setHeader(header, ovr)
            yield test
          end
        end
      end

      test_methods.each do |tm|
        OVERRIDE_URL_PARMS.each do |p|
          OVERRIDE_METHODS.each do |ovr|
            next if ovr == tm
            parm = Watobo::UrlParameter.new(:name => p, :value => ovr)
            test = request.clone
            test.method = tm
            test.set parm
            yield test
          end
        end
      end
    end
  end
end