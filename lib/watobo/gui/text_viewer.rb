# @private 
module Watobo#:nodoc: all
  module Gui
    class TextView2 < FXText

      attr_accessor :max_len

      public
      def subscribe(event, &callback)
        (@event_dispatcher_listeners[event] ||= []) << callback
      end

      def clearEvents(event)
        @event_dispatcher_listener[event].clear
      end

      def matchIndex()
        @match_index
      end

      def numMatches()
        @pattern_matches.length
      end

      def showNextMatch()
       # puts "* showNextMatch -> #{@match_index+1}"
        showMatch(@match_index + 1)
      end

      def showPrevMatch()
       # puts "* showPrevMatch -> #{@match_index-1}"
        showMatch(@match_index - 1)
      end

      def setFont(font_type=nil, size=nil)
        new_size = size.nil? ? GUI_REGULAR_FONT_SIZE : size
        new_font_type = font_type.nil? ? "helvetica" : font_type
        new_font = FXFont.new(getApp(), new_font_type, new_size)
        new_font.create
        self.font = new_font
      end
      
      def highlight_code(pattern=nil)
        # remove all styles
        self.changeStyle(0, self.length-1, 0)
        mark = pattern.nil? ? @code_pattern : pattern
        sindex = nil
        pos = 0
        match = []
        text = self.to_s
        mark = "%%"

        loop do
          sindex = text.index(mark, pos)
          nli = text.index("\n", pos)
          break if sindex.nil?
          puts pos
          
          unless nli.nil?
            match = [] if nli < sindex
          end
          
          match << sindex
          
          if match.length == 2          
            start = match[0]
            len = match[1] - match[0] + mark.length
            
            self.changeStyle(start, len, @code_style)
            match = []
            pos = sindex + mark.length - 1
          else
            pos = sindex + mark.length            
          end
          
          break if pos >= self.length-1 + mark.length
        end
      end

      def initialize(owner, opts)

        @pattern_matches = []
        @raw_text = ""
        @match_index = 0
        @event_dispatcher_listeners = Hash.new
        @parse_code = true
        @code_pattern = "%%"
        @code_style = 1

        super(owner, opts)

        # Construct some hilite styles
        hs_green = FXHiliteStyle.new
        hs_green.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_green.normalBackColor = FXRGBA(0,255,0,1)   # FXColor::White
        hs_green.style = FXText::STYLE_BOLD

        hs_red = FXHiliteStyle.new
        hs_red.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
        hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
        hs_red.style = FXText::STYLE_BOLD

        # Enable the style buffer for this text widget
        self.styled = true
        # Set the styles
        self.hiliteStyles = [ hs_green, hs_red]

        self.editable = false

        self.textStyle |= TEXT_WORDWRAP
        
        self.connect(SEL_CHANGED){
          if @parse_code
            highlight_code()
          end
        }

      end

      def setPrintable(text, prefs={})
        @raw_text = text
        self.setText(normalizeText(@raw_text))
      end

      # applies a specific filter (string or regex).
      #
      # It returns an array containing [pos, len] pairs of each match

      def applyFilter(pattern, prefs={})
        cprefs = { :highlight => true,
          :style_index => 2}
        cprefs.update(prefs) if prefs.is_a? Hash

        dummy = self.to_s
        #remove previous highlighting
        self.killSelection()
        self.setText(dummy)
        @match_index = 0
        @pattern_matches = matchPattern(pattern)
        if cprefs[:highlight] == true
          # puts "* found pattern #{pattern} #{@pattern_matches.length} times"
          @pattern_matches.each do |start, len|
            begin
              self.changeStyle(start, len, cprefs[:style_index])
            rescue => bang
              puts "outch"
              puts bang
            end
          end
        end

        # now re-highlight input and set cursor to last pos

        return @pattern_matches
      end

      # reset()
      # this function removes all previous selections and highlightings
      def reset_text()
        self.setText(self.to_s)
      end

      # showMatch(index=0)
      # this function makes a specific match visible in the text field.
      # The default index value is 0.
      # The function returns the index of the current match index.
      def showMatch(match_index=0, prefs={})
        cprefs = { :select_match => false }
          
        cprefs.update prefs
        
        return @match_index if @pattern_matches.empty?
        return @match_index if match_index > ( @pattern_matches.length - 1 )
        return @match_index if match_index < 0
        
        if @pattern_matches[match_index] then
          @match_index = match_index
          pos = @pattern_matches[match_index][0]
          len =@pattern_matches[match_index][1]

          self.setCenterLine(pos)

          #   @textbox.makePositionVisible(pos + len)
          self.makePositionVisible(self.lineEnd(pos))
          self.makePositionVisible(pos)

          self.setCursorPos(pos)

          self.killSelection()
          self.setSelection(pos, len) if cprefs[:select_match] == true
        end
        return @match_index
      end

      private

      # returns an array of matches. each match consists of two values [start, len]
      def matchPattern(pattern)
        sindex = nil
        eindex = nil

        pos = 0
        pattern_matches = []

        loop do
          sindex, eindex = self.findText(pattern, pos, SEARCH_EXACT|SEARCH_IGNORECASE|SEARCH_FORWARD)

          sindex, eindex = self.findText(pattern, pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex

          sindex, eindex = self.findText(Regexp.quote(pattern), pos, :flags => SEARCH_REGEX|SEARCH_IGNORECASE|SEARCH_FORWARD) if not sindex

          break if not sindex or sindex.length == 0

          pos = eindex.last+1
          sindex.length.times do |i|
            start = sindex[i]
            len = eindex[i] - sindex[i]
            pattern_matches.push [ start, len] if start >= 0
          end

          break if sindex.last < 0

        end

        return pattern_matches
      end

      def notify(event, *args)
        if @event_dispatcher_listeners[event]
          @event_dispatcher_listeners[event].each do |m|
            m.call(*args) if m.respond_to? :call
          end
        end
      end

      def normalizeText(text)
        return "" if text.nil?
        
        ntext = "#{text}"
        ntext.gsub!("\r",'')
       
        #   t = text.join.gsub(/\r/,"") if text.is_a? Array
        last = 0
        while last < text.length
          match = ntext[last..-1].index("\n")
          if match
            nc = ntext[last..match-1].gsub(/[^[:print:]]/,'.')
            ntext[last..match-1] = nc
            # puts nc
            last += match+1
            while ntext[last] == "\n" do
              last += 1
              #  puts last
            end
          else
            break
          end
        end

        ntext        
      end

      def log(text)
        t = Time.now
        now = t.strftime("%m/%d/%Y @ %H:%M:%S")
        msg = "[#{now}] #{text}"
        notify(:error, msg)
      end

    end # of TextViewer2

  end
end