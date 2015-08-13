# @private 
module Watobo#:nodoc: all
  module Gui
    class StatusBar < FXHorizontalFrame
      def setStatusInfo( prefs={} )
        cprefs = {
          :color => self.parent.backColor,
          :text => ''
        }

        cprefs.update prefs unless prefs.nil?

        @statusInfo.text = cprefs[:text]
        unless cprefs[:color].nil?
          @statusInfo.backColor = cprefs[:color]
        end
        

      end
      
      def update_proxy_mode
       # puts "Update Proxy Mode ..."
        if Watobo::Conf::Interceptor.proxy_mode == Watobo::Interceptor::MODE_REGULAR
       #   puts "REGULAR MODE"
          @portNumber.backColor = @portNumber.parent.backColor
          @port_label.backColor = @port_label.parent.backColor
        else
       #   puts "TRANSPARENT MODE"
          @portNumber.backColor = FXColor::Red
          @port_label.backColor = FXColor::Red
        end
      end

      def statusInfoText=( new_text )
        @statusInfo.text = new_text
        @statusInfo.backColor = self.parent.backColor
      end

      def projectName=(project_name)
        @projectName.text = project_name
      end

      def sessionName=(session_name)
        @sessionName.text = session_name
      end

      def portNumber=(port_number)
        @portNumber.text = port_number
      end

      def forwardingProxy=(forward_proxy)
        @forwardingProxy.text = forward_proxy
      end
      
      def bindAddress=(bind_addr)
        @bind_addr_label.text = "Bind-Addr: #{bind_addr} "
      end

      def initialize(owner, opts)
        super(owner, opts)

        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
        FXLabel.new(frame, "Status: ")
        @statusInfo = FXLabel.new(frame, "- no project started -")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
        FXLabel.new(frame, "Project: ")
        @projectName = FXLabel.new(frame, " - ")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
        FXLabel.new(frame, "Session: ")
        @sessionName = FXLabel.new(frame, " - ")
        
        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)

        #@bind_label = FXLabel.new(frame, "BindAddr: ")
        @bind_addr_label = FXLabel.new(frame, "Bind-Addr: - ")

        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)

        @port_label = FXLabel.new(frame, "Port: ")
        # @port_label.connect(SEL_RIGHTBUTTONPRESS) { switch_proxy_mode }
        @portNumber = FXLabel.new(frame, " - ")
        # @portNumber.connect(SEL_RIGHTBUTTONPRESS) { switch_proxy_mode }

        frame = FXHorizontalFrame.new(self, :opts => FRAME_SUNKEN, :padding => 0)
        FXLabel.new(frame, "Forwarding Proxy: ")
        @forwardingProxy = FXLabel.new(frame, " - ")
      end

      private

      def switch_proxy_mode

        if RUBY_PLATFORM =~ /linux/i
          puts "SWITCHING PROXY MODE ..."
          if Watobo::Interceptor.proxy_mode == Watobo::Interceptor::MODE_TRANSPARENT
            mode = "Regular"
            #  Watobo::NFQueue.stop
            Watobo::Interceptor.proxy_mode = Watobo::Interceptor::MODE_REGULAR
          @portNumber.backColor = @portNumber.parent.backColor
          @port_label.backColor = @port_label.parent.backColor
          else
            mode = "Transparent"
            # t = Watobo::NFQueue.start
            Watobo::Interceptor.proxy_mode = Watobo::Interceptor::MODE_TRANSPARENT
            @portNumber.backColor = FXColor::Red
            @port_label.backColor = FXColor::Red
          # puts t.status
          end
          puts "current mode: #{mode}"
        else
          puts "COULD NOT SWITCH PROXY-MODE"
          puts "Reason: Platform Not Supported"
        end
      end
    end
  # class end
  end
end
