# @private 
module Watobo#:nodoc: all
  module Plugin
    module Sslchecker
      module Gui
        
        
      class Main < Watobo::Plugin2

        include Watobo::Constants
        
        icon_file "sslchecker.ico"
        
        def createChat(site)
          chat = nil
         
          unless site =~ /^http/
            url = "https://#{site}/"
          else
            url = site
          end
          request = []
          request << "GET #{url} HTTP/1.1\r\n"
          request << "Host: #{site}\r\n"
          request << "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, application/vnd.ms-excel, application/vnd.ms-powerpoint, application/msword, */*\r\n"
          request << "Accept-Language: de\r\n"
          request << "Proxy-Connection: close\r\n"
          request << "User-Agent: Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)\r\n"
          request << "\r\n"
          
          puts request

          chat = Watobo::Chat.new(request, [], :id => 0)

          return chat
        end

        def onSiteSelect(sender, sel, item)
          if sender.numItems > 0
          @site = sender.getItemData(sender.currentItem)
          else
            unless sender.text.empty?
            @site = sender.text.gsub(/^https?:\/\//,"").strip 
            end
          end
         
        end

         def updateView()
            #@project = project
            @site = nil
            @sites_combo.clearItems()
            #@dir_combo.clearItems()
            unless Watobo.project.nil? then
              count = 0
              Watobo::Chats.sites(:ssl => true, :in_scope => Watobo::Scope.exist? ).each do |site|
              #puts "Site: #{site}"
                count += 1
                @sites_combo.appendItem(site, site)
              end
              if @sites_combo.numItems > 0
                @sites_combo.setCurrentItem(0)
                @site = @sites_combo.getItemData(0)
                @sites_combo.numVisible = ( @sites_combo.numItems > 15 ) ? 15 : @sites_combo.numItems
             # else
             #   @log_viewer.log(LOG_INFO,"No SSL Sites available - you need to visit a SSL Site first!")
              elsif Watobo::Scope.exist?
                 @sites_combo.appendItem("no site for defined scope", nil)
              end
            end

          end
          
          def create
            super
            
            updateView()
          end

        def start(sender, sel, item)
          unless @site.nil?
            
            
          unless Watobo::ForwardingProxy.get(@site).nil?
             @log_viewer.log(LOG_INFO,"!!! WARNING FORWARDING PROXY IS SET !!! - SSL-Check through proxy not possible!")
             FXMessageBox.information(self,MBOX_OK,"Forwarding proxy is set", "SSL-Checks through proxy not possible!")
             return false
          end
          
          @cipher_table.clear_ciphers

          chat = createChat(@site)
          checklist = []
          checklist.push @check
          chatlist = []
          chatlist.push chat
          scan_prefs = Watobo::Conf::Scanner.to_h
          @scanner = Watobo::Scanner3.new(chatlist, checklist, nil, scan_prefs)

          @pbar.total = @scanner.sum_total
          @pbar.progress = 0
          @pbar.barColor = 'red'
            
            
          @update_lock.synchronize do 
             @status = :running
          end
             
          @log_viewer.log LOG_INFO, "Scan started with #{@check.cipherlist.length} ciphers ..."
          #  @scan_thread = Thread.new(scanner) { |scan|
          begin

            @scanner.run()
               # sleep 1 # to let the update_timer finish its work
               # getApp().removeTimeout(@update_timer) 
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
            #}

       end
    end

        def initialize(owner, project)
          super(owner, "SSL-Plugin", project, :opts => DECOR_ALL,:width=>800, :height=>600)

          @plugin_name = "SSL-Checker"
          @project = project
          @site = nil
          @dir = nil
          @scan_thread = nil
          @pbar = nil
          @scanner = nil
          
          @results = []
          @results_lock = Mutex.new
       #   @status_lock = Mutex.new
          @status = :idle
          
           @clipboard_text = ""
        self.connect(SEL_CLIPBOARD_REQUEST) do
        # setDNDData(FROM_CLIPBOARD, FXWindow.stringType, Fox.fxencodeStringData(@clipboard_text))
          setDNDData(FROM_CLIPBOARD, FXWindow.stringType, @clipboard_text + "\x00" )
        end
          
          mr_splitter = FXSplitter.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y|SPLITTER_VERTICAL|SPLITTER_REVERSED|SPLITTER_TRACKING)
          # top = FXHorizontalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_SIDE_BOTTOM)
          top_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_FIX_HEIGHT|LAYOUT_BOTTOM,:height => 500)
          top_splitter = FXSplitter.new(top_frame, LAYOUT_FILL_X|SPLITTER_HORIZONTAL|LAYOUT_FILL_Y|SPLITTER_TRACKING)
          log_frame = FXVerticalFrame.new(mr_splitter, :opts => LAYOUT_FILL_X|LAYOUT_SIDE_BOTTOM,:height => 100)

          @settings_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_Y)
          result_frame = FXVerticalFrame.new(top_splitter, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          
          @controller = CipherTableController.new(result_frame, :opts => LAYOUT_FILL_X)
          @controller.subscribe(:apply_filter){ |f| @cipher_table.filter = f ; @cipher_table.update_table}
          @controller.subscribe(:copy_table){
             types = [ FXWindow.stringType ]
                    if acquireClipboard(types)
                    puts
                    @clipboard_text = @cipher_table.to_csv
                    end

          }

         frame = FXVerticalFrame.new(result_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
         @cipher_table = CipherTable.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

          FXLabel.new(@settings_frame, "Enter or select site to test:")
          @sites_combo = FXComboBox.new(@settings_frame, 5, nil, 0, COMBOBOX_STATIC|FRAME_SUNKEN|FRAME_THICK|LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
           #@sites_combo = FXTextField.new(@settings_frame, 25, :opts => TEXTFIELD_NORMAL|LAYOUT_FILL_COLUMN|LAYOUT_RIGHT)
          #@filterCombo.width =200

          @sites_combo.numColumns = 35
          @sites_combo.editable = true
          @sites_combo.connect(SEL_COMMAND, method(:onSiteSelect))
          begin

       
            @pbar = FXProgressBar.new(@settings_frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
            
            @pbar.progress = 0
            @pbar.total = 0
            @pbar.barColor=0
            @pbar.barColor = 'grey' #FXRGB(255,0,0)

            @start_button = FXButton.new(@settings_frame, "start")
            @start_button.connect(SEL_COMMAND, method(:start))

            @check = Check.new(@project)

            @check.subscribe(:cipher_checked) { |result|
              begin
                @results_lock.synchronize do
                @results << result
                end
               #  FXApp.instance.forceRefresh
              rescue => bang
              puts bang
              puts bang.backtrace if $DEBUG
              end
            #puts "#{@pbar.progress} of #{@pbar.total}"
            #     logger

            }

            log_frame_header = FXHorizontalFrame.new(log_frame, :opts => LAYOUT_FILL_X)
            FXLabel.new(log_frame_header, "Logs:" )

            #log_text_frame = FXHorizontalFrame.new(bottom_frame, :opts => LAYOUT_FILL_X|FRAME_SUNKEN|LAYOUT_BOTTOM)
            log_text_frame = FXVerticalFrame.new(log_frame, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN|FRAME_THICK, :padding=>0)
            @log_viewer = LogViewer.new(log_text_frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)

            updateView()
           
          rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
          end

        end
        
        private
        def reset_pbar
           @pbar.progress = 0
           @pbar.total = 0
           @pbar.barColor = 'grey' #FXRGB(255,0,0)
        end
        
        def on_update_timer
           unless @scanner.nil?
             progress = @scanner.progress
             sum_progress = progress.values.inject(0){|i, v|  i += v[:progress] }
                     
            @pbar.progress = sum_progress
            
            if @scanner.finished?             
              msg = "Scan Finished!"              
              @log_viewer.log(LOG_INFO, msg)
              Watobo.log(msg, :sender => "Catalog")              
              @scanner = nil
              reset_pbar()
            
            @start_button.text = "Start"
            end
           end
         
         
          @results_lock.synchronize do             
               @results.each do |r|
                 @cipher_table.add_cipher(r)
               end
               @results.clear               
           end

        end
        
        
        
      end
      end
      end
      end
      end