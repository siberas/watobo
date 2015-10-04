require 'fox16'

include Fox


class FXLoginWizzard < FXDialogBox
  
  attr_accessor :sid_patterns
  attr_accessor :requestids
  attr_accessor :project
  
  private
    
  def onPatternClick(sender,sel,item)
    @lastpattern=item
    highlight_pattern(@pattern_list.getItemText(item))  
    @pattern.value = @pattern_list.getItemText(item)
    @pattern.handle(self, FXSEL(SEL_UPDATE, 0), nil)
  end
  
  def onRequestClick(sender,sel,item)
    @lastid=item
    chat = Watobo::Chats.get_by_id(@request_list.getItemText(@lastid))
    if chat then
      show_chat(chat)
    end
    
  end
  
  def show_chat(chat)
    @requestView.setText('')
    # Enable the style buffer for this text widget
    @requestView.styled = true
    
    atext=chat.request.join
    atext.gsub!(/\r/, "")
    @requestView.appendStyledText("#{atext}")
    
    @responseView.setText('')
    # Enable the style buffer for this text widget
    @responseView.styled = true
    
    atext=chat.response.join
    atext.gsub!(/\r/, "")
    @responseView.appendStyledText("#{atext}")
  end
  
  def update_request_list(idlist)
    @request_list.clearItems
    idlist.each do |chatid|
      
      chat = Watobo::Chats.get_by_id(chatid)
      puts chat.id
      if chat then
        #puts chatid
        @lastid = @request_list.appendItem("#{chatid}")
        @request_list.setItemData(@lastid, chat)
      end
    end
  end
  
  
  
  
  def highlight_pattern(pattern)
    return if @lastpattern < 0
    return if @lastid < 0
    
    chat = @request_list.getItemData(@lastid)
    req_text=chat.request.join
    req_text.gsub!(/\r/, "")
    
    @requestView.setText("")
    @requestView.appendStyledText("#{req_text}")
    
    resp_text=chat.response.join
    resp_text.gsub!(/\r/, "")
    @responseView.setText("")
    @responseView.appendStyledText("#{resp_text}")
    begin
      if req_text =~ /#{pattern}/ then
        if $1 and $2 then
          string1 = $1
          string2 = $2
        else
          string1 = pattern
          string2 = pattern
        end
        if req_text.index(string1) then
          @requestView.changeStyle(req_text.index(string1),string1.length,1)
          @requestView.changeStyle(req_text.index(string2),string2.length,1)
        end      
      end
      
      if resp_text =~ /#{pattern}/ then
        if $1 and $2 then
          string1 = $1
          string2 = $2
        else
          string1 = pattern
          string2 = pattern
        end
        if resp_text.index(string1) then
          @responseView.changeStyle(resp_text.index(string1),string1.length,1)
          @responseView.changeStyle(resp_text.index(string2),string2.length,1)
        end       
      end  
    rescue
      puts "+ no valid regex"
    end
    
  end
  
  def addPattern(sender,sel,id)
    if @pattern != "" then
      @sid_patterns.push @pattern.value
      update_pattern_list
    end
  end
  
  def remPattern(sender,sel,id)
    if @lastpattern >= 0 then
      pattern = @pattern_list.getItemText(@lastpattern)
      #@pattern_list.removeItem(@lastpattern)
      @sid_patterns.delete(pattern)
      @lastpattern = -1
      update_pattern_list
    end
  end
  
  def remRequest(sender,sel,id)
    if @lastid >= 0 then
      id = @request_list.getItemText(@lastid)
      
      #@pattern_list.removeItem(@lastpattern)
      @requestids.delete(id)
      @lastid = -1
      update_request_list(@requestids)
    end
  end
  
  def updatePatternList
    @pattern_list.clearItems
    @sid_patterns.each do |pat|
      @pattern_list.appendItem("#{pat}")
    end
  end
  
  public
  
  def add_request(chatid)
    
    @requestids.push "#{chatid}"
    chat = nil
    
    
    @project.chat_list.each do |c|
      chat = c
      # puts "#{chat.id} : #{chatid}"
      break if c.id == chatid
    end
    
    
    show_chat(chat)
    update_request_list(@requestids)
    
  end
  
  
  
  
  def initialize(owner, project)
    @project = project
    # Invoke base class initialize function first
  #  super(owner, "LoginScript Wizzard", DECOR_TITLE|DECOR_BORDER,:width=>800, :height=>600)
    super(owner, "LoginScript Wizzard", DECOR_ALL,:width=>800, :height=>600)
    
    #self.icon = icon
  #  @project = nil
    @sid_patterns = []
    @requestids = []
    @pattern = FXDataTarget.new("")
    
    @sid_patterns = @project.settings[:sid_patterns].clone
    @requestids = @project.loginscript_ids.clone 
    
    
    @lastid=-1
    @lastpattern=-1
    
    lw_main = FXPacker.new(self, :opts => LAYOUT_FILL)
    lw_bottom = FXHorizontalFrame.new(lw_main, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM)
    lw_body = FXHorizontalFrame.new(lw_main, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_TOP)
    
    
    #=============================================================================================
    # body
    
    lw_left = FXVerticalFrame.new(lw_body, :opts => LAYOUT_FILL_Y|LAYOUT_SIDE_LEFT)
    lw_right = FXVerticalFrame.new(lw_body, :opts => LAYOUT_FILL_Y|LAYOUT_SIDE_RIGHT|LAYOUT_FILL_X)
    
    
    #=============================================================================================
    # lw_right
    
    req_frame = FXVerticalFrame.new(lw_right, :opts => LAYOUT_FILL_X| LAYOUT_FILL_Y|FRAME_GROOVE)
    resp_frame = FXVerticalFrame.new(lw_right, :opts => LAYOUT_FILL_X| LAYOUT_FILL_Y|FRAME_GROOVE)
    
    FXLabel.new(req_frame, "Requests:" )                      
    @requestView = FXText.new(req_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
    
    # Construct some hilite styles
    hs_red = FXHiliteStyle.new
    hs_red.normalForeColor = FXRGBA(255,255,255,255) #FXColor::Red
    hs_red.normalBackColor = FXRGBA(255,0,0,1)   # FXColor::White
    hs_red.style = FXText::STYLE_BOLD
    # Enable the style buffer for this text widget
    @requestView.styled = true
    # Set the styles
    @requestView.hiliteStyles = [hs_red]
    
    
    
    FXLabel.new(resp_frame, "Response:" )                      
    @responseView = FXText.new(resp_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @responseView.styled = true
    # Set the styles
    @responseView.hiliteStyles = [hs_red]
    
    #=============================================================================================
    # sid-pattern
    sid_frame = FXVerticalFrame.new(lw_left, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
    lw_sid = FXHorizontalFrame.new(sid_frame, :opts => LAYOUT_FILL_X)
    FXLabel.new(lw_sid, "Pattern:" )
    FXTextField.new(lw_sid, 20,
                    :target => @pattern, :selector => FXDataTarget::ID_VALUE,
                    :opts => TEXTFIELD_NORMAL|LAYOUT_SIDE_LEFT)
    
    addPattern=FXButton.new(lw_sid, " + " , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
    addPattern.connect(SEL_COMMAND, method(:addPattern))
    
    remPattern=FXButton.new(lw_sid, " - " , :opts => BUTTON_NORMAL|LAYOUT_LEFT)
    remPattern.connect(SEL_COMMAND, method(:remPattern))
    
    @pattern_list = FXList.new(sid_frame, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @pattern_list.numVisible = 8
    
    @pattern_list.connect(SEL_COMMAND,method(:onPatternClick))
    
    updatePatternList
    
    
    
    #=============================================================================================
    # request-list
    
    lw_req_list = FXVerticalFrame.new(lw_left, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
    lw_request_list_header = FXHorizontalFrame.new(lw_req_list, :opts => LAYOUT_FILL_X)
    FXLabel.new(lw_request_list_header, "Login-Requests:" )
    
    @request_list = FXList.new(lw_req_list, :opts => LIST_EXTENDEDSELECT|LAYOUT_FILL_X|LAYOUT_FILL_Y)
    @request_list.connect(SEL_COMMAND,method(:onRequestClick))
    
    remRequest=FXButton.new(lw_request_list_header, " - " , :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
    remRequest.connect(SEL_COMMAND, method(:remRequest))
    #=============================================================================================
    
    
    
    #=============================================================================================
    # lw_bottom    
    
    FXButton.new(lw_bottom, "OK" ,
    :target => self, :selector => FXDialogBox::ID_ACCEPT,
    :opts => BUTTON_NORMAL|LAYOUT_RIGHT)
    FXButton.new(lw_bottom, "Cancel" ,
    :target => self, :selector => FXDialogBox::ID_CANCEL,
    :opts => BUTTON_NORMAL|LAYOUT_RIGHT)    
  end 
end
