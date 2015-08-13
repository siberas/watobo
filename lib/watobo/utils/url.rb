# @private 
module Watobo#:nodoc: all
  module Utils
    module URL
      def self.create_url(chat, path)
        url = path
        # only expand path if not url
        unless path =~ /^http/
          # check if path is absolute
          if path =~ /^\//
            url = File.join("#{chat.request.proto}://#{chat.request.host}", path)
          else
            # it's relative
            url = File.join(File.dirname(chat.request.url.to_s), path)
          end
        end
        # resolve path traversals
        while url =~ /(\/[^\.\/]*\/\.\.\/)/
          url.gsub!( $1,"/")
        end
        url
      end
    end
  end
end