require 'watobo/gui/request_editor'
# @private 
module Watobo#:nodoc: all
  module Gui
    class TaglessViewer < SimpleTextView
      def normalizeText(text)
        return '' if text.nil?
        
        raw_text = text
        
        if text.is_a? Array then
        raw_text = text.join
        end

        #remove headers
        body_start = raw_text.index("\r\n\r\n")
        body_start = body_start.nil? ? 0 : body_start
        #puts "* start normalizing at pos #{body_start}"
        normalized = raw_text[body_start..-1]
        # UTF-8 Clean-Up
        normalized = normalized.unpack("C*").pack("C*")
        # remove all inbetween tags
        normalized.gsub!(/<.*?>/m, '')
        # remove non printable characters, except LF (\x0a)
         r = Regexp.new '[\x00-\x09\x0b-\x1f\x7f-\xff]+', nil, 'n'
        normalized.gsub!( r,'')
        # remove empty lines
        normalized.gsub!(/((\x20+)?\x0a(\x20+)?)+/,"\n")
       # decode html entities for better readability
        normalized = CGI.unescapeHTML(normalized)
        # additionally unescape &nbsp; which is not handled by CGI :(
        normalized.gsub!(/(#{Regexp.quote('&nbsp;')})+/," ")
        # finally strip it
        normalized.strip
      end

      def initialize(owner, opts)
        super(owner, opts)
      end
    end

  end
end
