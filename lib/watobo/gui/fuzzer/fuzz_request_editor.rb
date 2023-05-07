require 'watobo/gui/request_editor.rb'
# @private
module Watobo #:nodoc: all
  module Gui

    class FuzzRequestEditor < Watobo::Gui::RequestEditor

      def parseRequest(fuzzels = [])
        begin
          new_request = nil
          new_request = @textbox.to_s
          fuzzels.each do |marker, value|
            new_request.gsub!(/%%#{marker}%%/, value.to_s)
          end


          #return Watobo::Utils.text2request(new_request)
          return Watobo::Request.new(new_request)
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil
      end


      def addTag(tag)
        @tags.push tag
      end

      def removeTag(tag)
        @tags.delete(tag)
      end

      def highlightTags()
        highlight("(%%[^%]*%%)")
      end

      def initialize(owner, opts)
        super(owner, opts)

        @tags = []

      end

    end

    class FuzzRequestEditor_UNUSED < Watobo::Gui::RequestEditor


      def highlight(pattern)
        sindex = nil
        eindex = nil

        # clear current highlighting
        dummy = @textbox.to_s
        @textbox.setText(dummy)

        pos = 0
        @pattern_matches.clear

        loop do

          sindex, eindex = @textbox.findText(pattern, pos, SEARCH_EXACT | SEARCH_IGNORECASE | SEARCH_FORWARD)
          #   puts sindex
          sindex, eindex = @textbox.findText(pattern, pos, :flags => SEARCH_REGEX | SEARCH_IGNORECASE | SEARCH_FORWARD) if not sindex
          #  puts sindex
          sindex, eindex = @textbox.findText(Regexp.quote(pattern), pos, :flags => SEARCH_REGEX | SEARCH_IGNORECASE | SEARCH_FORWARD) if not sindex

          break if not sindex or sindex.length == 0


          pos = eindex.last + 1

          sindex.length.times do |i|
            start = sindex[i]
            len = eindex[i] - sindex[i]
            @pattern_matches.push [start, len] if start >= 0

          end

          break if sindex.last < 0
          #   puts sindex

        end

        # puts "* found pattern #{pattern} #{@pattern_matches.length} times"

        @pattern_matches.each do |start, len|
          begin
            style = @style
            match = @textbox.to_s.slice(start, len)
            # puts "#{match}/#{start}/#{len}"
            match.gsub!(/%%/, '')
            style = @tags.include?(match) ? 1 : 2

            @textbox.changeStyle(start, len, style)
          rescue => bang
            puts "outch"
            puts bang
          end
        end
        return @pattern_matches
      end


      def parseRequest(fuzzels)
        begin
          new_request = nil
          if fuzzels then
            new_request = @textbox.to_s
            fuzzels.each do |marker, value|
              new_request.gsub!(/%%#{marker}%%/, value.to_s)
            end
          end

          #return Watobo::Utils.text2request(new_request)
          return Watobo::Request.new(new_request)
        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
        return nil
      end

      def addTag(tag)
        @tags.push tag
      end

      def removeTag(tag)
        @tags.delete(tag)
      end

      def highlightTags()
        highlight("(%%[^%]*%%)")
      end

      def initialize(owner, opts)
        super(owner, opts)

        @tags = []

      end
    end
  end
end
