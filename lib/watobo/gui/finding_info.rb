require 'fox16/colors'
# @private 
module Watobo#:nodoc: all
  module Gui
    class FindingInfo < FXVerticalFrame
      include Watobo::Gui::Icons
      include Watobo::Constants
      
      def resetInfo()
        @finding_title.text = "-"
        @finding_date.text = "-"
        @finding_module.text = "-"
        @finding_check.text = "-"
        @finding_proof.text = "-" 
        @finding_threat.text = "-"
        @finding_rating.text = "-"
        @finding_cvss.text = "-"             
        @finding_measure.text = "-"
        
       # @finding_references.text = "-"
        
      end
      
      def showInfo(finding)
     #   p "* show info"
        resetInfo()
        case finding.details[:type]
          when FINDING_TYPE_INFO
          
          icon = ICON_INFO_INFO
           rating = "Info"
          
          when FINDING_TYPE_HINT
          
          icon = ICON_HINTS_INFO
           rating = "Hint"
          
          
          when FINDING_TYPE_VULN
          
          if finding.details[:rating] == VULN_RATING_LOW
            icon = ICON_VULN_LOW
            rating = "Low"
          end
          if finding.details[:rating] == VULN_RATING_MEDIUM
            icon = ICON_VULN_MEDIUM
            rating = "Medium"
          end
          if finding.details[:rating] == VULN_RATING_HIGH
            icon=ICON_VULN_HIGH
            rating = "High"
          end
          if finding.details[:rating] == VULN_RATING_CRITICAL
            icon=ICON_VULN_CRITICAL
            rating = "Critical"
          end
        end
        @finding_icon.icon = icon
        @finding_title.text = finding.details[:class]
        @finding_rating.text = rating
        @finding_threat.text = finding.details[:threat]
        @finding_measure.text = finding.details[:measure]
        @finding_details.text = (finding.details.has_key? :output) ? finding.details[:output] : finding.details[:details] 
        
        @finding_date.text = finding.details[:tstamp]
        @finding_module.text = finding.details[:module]
        @finding_chat.text = finding.id.to_s
        
        @finding_check.text = finding.details[:check_pattern]
        @finding_proof.text = finding.details[:proof_pattern]
        @finding_id.text = finding.id.to_s
        
        self.recalc()
        self.update()
      #  p "* ok"
      end
      
      def initialize(owner, opts)
        super(owner, opts)
        
        @font_title = FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT)
        @font_text = FXFont.new(getApp(), "courier", 12, FONTWEIGHT_BOLD)
        
        main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
        main.backColor = FXColor::White
        
        frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        frame.backColor = FXColor::White
      
        #@imageview = FXImageView.new(header, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|HSCROLLER_NEVER|VSCROLLER_NEVER)        
        #@imageview = FXImageView.new(header, :opts => LAYOUT_FIX_WIDTH|LAYOUT_FIX_HEIGHT|HSCROLLER_NEVER|VSCROLLER_NEVER, :width => 50, :height => 50)
        #@imageview.image = ICON_WATOBO
        @finding_icon = FXButton.new(frame, '', ICON_WATOBO, :opts => FRAME_NONE)
        @finding_icon.backColor = FXColor::White
        
        @finding_title  = FXLabel.new(frame, "- N/A -", nil, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        @finding_title.setFont(@font_title)
        @finding_title.backColor = FXColor::White
        @finding_title.justify = JUSTIFY_LEFT|JUSTIFY_CENTER_Y
        
        frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X)
        frame.backColor = FXColor::White
        label = FXLabel.new(frame, "Rating: ")
        label.backColor = FXColor::White
        label.setFont(@font_text)
        
        @finding_rating = FXLabel.new(frame, "- N/A -", nil, :opts => JUSTIFY_CENTER_X|LAYOUT_FILL_X)
        @finding_rating.setFont(@font_text)
        @finding_rating.backColor = FXColor::White
        @finding_rating.justify = JUSTIFY_LEFT
        
        
        frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        frame.backColor = FXColor::White
        label = FXLabel.new(frame, "Threat:")
        label.backColor = FXColor::White
        label.setFont(@font_title)
        
        threat = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        threat.backColor = FXColor::White
        #@finding_thread = FXLabel.new(thread, "- N/A -", nil, :opts => JUSTIFY_CENTER_X|LAYOUT_FILL_X)
        @finding_threat  = FXText.new(threat, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY|TEXT_WORDWRAP)
        # Enable the style buffer for this text widget
        @finding_threat .styled = true
        @finding_threat.setFont(@font_text)
        @finding_threat.backColor = FXColor::White
       # @finding_thread.justify = JUSTIFY_LEFT
        
        
        frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        frame.backColor = FXColor::White
        label = FXLabel.new(frame, "Measure:")
        label.backColor = FXColor::White
        label.setFont(@font_title)
        
        measure = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        measure.backColor = FXColor::White
        @finding_measure =FXText.new(measure, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY|TEXT_WORDWRAP) 
        #FXLabel.new(measure, "- N/A -", nil, :opts => JUSTIFY_CENTER_X|LAYOUT_FILL_X)
        @finding_measure.setFont(@font_text)
        @finding_measure.backColor = FXColor::White
       # @finding_measure.justify = JUSTIFY_LEFT
       
       frame  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        frame.backColor = FXColor::White
        label = FXLabel.new(frame, "Details:")
        label.backColor = FXColor::White
        label.setFont(@font_title)
        
        details = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        details.backColor = FXColor::White
        @finding_details =FXText.new(details, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|TEXT_READONLY|TEXT_WORDWRAP) 
        @finding_details.setFont(@font_text)
        @finding_details.backColor = FXColor::White
       
        
        
         info  = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
        info.backColor = FXColor::White
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
         
        FXLabel.new(frame, "Finding-ID:")
        @finding_id = FXLabel.new(frame,"-")
        
        
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Date:")
        @finding_date = FXLabel.new(frame,"-")
        
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Module:")
        @finding_module = FXLabel.new(frame,"-")
        
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
                FXLabel.new(frame, "Chat-ID:")
                @finding_chat = FXLabel.new(frame,"-")
                       
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Check-Pattern:")
        @finding_check = FXLabel.new(frame,"-")
        
        frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Proof-Pattern:")
        @finding_proof = FXLabel.new(frame,"-")        
        
         frame = FXHorizontalFrame.new(info, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "CVSS (Base-Score):")
        @finding_cvss = FXLabel.new(frame,"-")
      end
      
    end
  end
end
