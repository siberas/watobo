#
# XML/SOAP Resources
#
# http://calagenda.berkeley.edu/help_training/developer/calendar-ws/sample-code/ruby-soap4r/geteventsbyrange.rb
# http://www.service-repository.com/
#
# @private 
module Watobo#:nodoc: all
  module Gui
    
    class XmlTree < FXTreeList
      
      def addTreeElement(parent=nil, element=nil)
        node = self.appendItem(parent, element.name)
        element.elements.each do |e|
          sn = self.appendItem(node, e.name)
          if e.has_elements?
            e.elements.each do |se|
              self.addTreeElement(sn, se)
            end
            
          end
        end
      end
      
      def initialize(parent, xml_data=nil)
        super(parent, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_TOP|LAYOUT_RIGHT|TREELIST_SHOWS_LINES|TREELIST_SHOWS_BOXES|TREELIST_ROOT_BOXES|TREELIST_EXTENDEDSELECT)
        @xml_data = REXML::Document.new(xml_data)
        @root = @xml_data.root
      #  @root.each_recursive { |x| 
       #puts x.name if x.has_text? and x.text == "?"
      # puts x.name #unless x.has_elements?
       #}
        #puts @xml_data.root.methods.sort
        
       addTreeElement(nil, @root)
        
      end
    end
    
    class XmlViewerFrame < FXVerticalFrame
      
      
      
      def initialize(owner, xmldata=nil, opts=0)
        super(owner, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y , :padding => 0)
        @xml_tree = XmlTree.new(self, xmldata)
        #puts xmldata
      end
      
      
      
    end #EOC
    #--
  end
end


if __FILE__ == $0
  require 'rexml/document'
   
  include REXML
  
  xmldata = '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ort="http://www.mathertel.de/OrteLookup/">
   <soap:Header/>
   <soap:Body>
      <ort:GetPrefixedEntries>
         <!--Optional:-->
         <ort:prefix>?</ort:prefix>
      </ort:GetPrefixedEntries>
   </soap:Body>
</soap:Envelope>'
  
  class TestGui < FXMainWindow
    
    def initialize(app, xmldata)
      # Call base class initializer first
      super(app, "Test Application", :width => 800, :height => 600)
      frame = FXVerticalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
      
      xmlframe = Watobo::Gui::XmlViewerFrame.new(frame, xmldata, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
    end
    # Create and show the main window
    def create
      super                  # Create the windows
      show(PLACEMENT_SCREEN) # Make the main window appear
      
    end
  end
  application = FXApp.new('LayoutTester', 'FoxTest')  
  TestGui.new(application, xmldata)
  application.create
  application.run
end
