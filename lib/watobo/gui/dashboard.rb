# @private 
module Watobo #:nodoc: all

  module Gui

    class ProgressInfo < FXVerticalFrame

      def increment(i)
        @lock.synchronize do
          @pbar.progress += i
          #@total += i
        end
      end

      def progress(i)
        @lock.synchronize do
          @pbar.progress = i
          update_bar_color
        end
      end

      def update_bar_color
        if @pbar.total == 0 then
          @pbar.barColor = 'grey'
        else
          @pbar.barColor = FXRGB(255, 0, 0)
        end
        if @pbar.progress == @pbar.total
          @pbar.barColor = 'green'
        end
      end

      def total(i)
        @lock.synchronize do
          #@progress = i
          @pbar.total = i
        end
      end

      def finished
        @lock.synchronize do
          @progress = @total
        end
      end

      def initialize(owner, check_name, num_checks)
        begin
          super(owner, :opts => LAYOUT_FILL_X|FRAME_GROOVE|LAYOUT_TOP)
          @lock = Mutex.new
          @check_name = check_name
          @label = FXLabel.new(self, check_name, :opts => LAYOUT_LEFT)

          #   puts l
          @pbar = FXProgressBar.new(self, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
          @pbar.progress = 0
          @pbar.total = num_checks
          puts "#{check_name} has #{num_checks} Checks"
          update_bar_color
        rescue => bang
          puts "!!!ERROR: could not add progress info"
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end
    end

    class ScanProgressFrame < FXVerticalFrame
      attr :progress_bars
      attr :scan_status

      include Watobo::Gui::Icons

      def setup(modules=[])
        @progress_bars.clear

        @progress_frame.each_child do |child|
          @progress_frame.removeChild(child)
        end


        #@progress_bars = Hash.new
        modules.each do |check_name, num_checks|
          puts "* new ProgressInfo: #{check_name} - #{num_checks}"
          pi = ProgressInfo.new(@progress_frame, check_name, num_checks[:total])
          pi.create

          @progress_bars[check_name] = pi
        end
        @progress_frame.recalc
        @progress_frame.update


      end

      def initialize(owner, opts)
        super(owner, opts)

        #   frame = FXScrollWindow.new(self, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        frame = FXScrollWindow.new(self, SCROLLERS_NORMAL|LAYOUT_FILL_X|LAYOUT_FILL_Y)
        info_container = FXVerticalFrame.new(frame, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
        frame = FXHorizontalFrame.new(info_container, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Scan-Status:")

        @scan_status = FXLabel.new(frame, "N/A")
        @progress_frame = FXVerticalFrame.new(info_container, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y, :padding => 0)
        #FXLabel.new(@main, "No Information Available")
        @progress_bars = Hash.new
      end
    end

    class ProjectInfo < FXVerticalFrame
      def update()
        if Watobo.project then
          Watobo::Gui.application.runOnUiThread do
            @project_name.text = Watobo.project.settings[:project_name]
            @session_name.text = Watobo.project.settings[:session_name]
            @project_path.text = Watobo.project.settings[:project_path]
            @session_path.text = Watobo.project.settings[:session_path]

            @number_active_checks.text = Watobo::ActiveModules.length.to_s
            @number_passive_checks = Watobo::PassiveModules.length.to_s
            @number_total_chats.text = Watobo::Chats.length.to_s
          end
        end

      end

      def initialize(owner, opts)
        super(owner, opts)
        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Project:")
        @project_name = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Session:")
        @session_name = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Project Path:")
        @project_path = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Session Path:")
        @session_path = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Number available ActiveModules:")
        @number_active_checks = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Number of PassiveModules:")
        @number_passive_checks = FXLabel.new(frame, "-")

        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        FXLabel.new(frame, "Number Current Chats:")
        @number_total_chats = FXLabel.new(frame, "-")

        #  frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        #  FXLabel.new(frame, "Number Critical Findings:")
        #  @number_critical_findings = FXLabel.new(frame,"-")

        #  frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        #  FXLabel.new(frame, "Number High Findings:")
        #  @number_high_findings = FXLabel.new(frame,"-")

        #  frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        #  FXLabel.new(frame, "Number Medium Findings:")
        #  @number_medium_findings = FXLabel.new(frame,"-")

        #  frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X)
        #  FXLabel.new(frame, "Number Low Findings:")
        #  @number_low_findings = FXLabel.new(frame,"-")
      end
    end


    class Dashboard < FXVerticalFrame
      include Watobo::Gui::Icons

      def setupScanProgressFrame(scanner)
        @progress_lock.synchronize do
          @scanner = scanner
          @scan_progress_frame.setup(scanner.progress)
        end
      end

      def setScanStatus(status)
        @scan_progress_frame.scan_status.text = status
      end

      def progressDisplays()
        return @scan_progress_frame.progress_bars()
      end

      def module_finished(mod)
        @progress_lock.synchronize do
          begin
            name = mod
            name = mod.info[:check_name] if mod.respond_to? :run_checks
            pbar = @scan_progress_frame.progress_bars[name]
            pbar.finished
              #pbar.progress = pbar.total
              # pbar.barColor = 'green' # FXRGB(0,255,0)
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
          end
        end
      end

      def progress(m)
        @progress_lock.synchronize do
          name = m
          name = m.info[:check_name] if m.respond_to? :run_checks
          @scan_progress_frame.progress_bars[name].increment(1)
          # p @scan_progress_frame.progress_bars[name].total
        end
      end

      def updateProjectInfo()
        @project_info_frame.update()
      end

      def update_status(check_module, progress_index)
        if @module_list.has_key?(check_module) then
          #puts "updating status window"
          pbar = @module_list[check_module][:progress]
          pbar.total = @project.chats.length-1
          pbar.progress = progress_index
          if progress_index == pbar.total

            pbar.barColor=FXRGB(0, 255, 0)
          end
        else
          puts "check_module not found in dashboard"
        end
      end

      def setup_status_bars(frame, module_list)

        module_list.each do |m|

          dummy = FXVerticalFrame.new(frame, LAYOUT_FILL_X|FRAME_GROOVE)
          dummy.create

          label = "undefined"
          begin

            label = m.check_name
          rescue => bang
            #  puts "no check name defined"
            # puts bang
          end
          # puts "."
          l = FXLabel.new(dummy, label, :opts => LAYOUT_LEFT)
          l.create
          #   puts l
          pbar = FXProgressBar.new(dummy, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)
          pbar.create

          pbar.progress = 0
          pbar.total = @project.chats.length-1
          pbar.barColor=0
          pbar.barColor=FXRGB(255, 0, 0)
          @module_list[m] = {
              :progress => pbar,
          }

        end

      end


      def start_update_timer
        #@timer = FXApp.instance.addTimeout(250, :repeat => true) {
        Thread.new {
          loop do
            sleep 0.5

            Watobo::Gui.application.runOnUiThread do

              unless @scanner.nil?
                progress = @scanner.progress
                progress.each do |m, info|
                  @scan_progress_frame.progress_bars[m].progress info[:progress]

                end
              end
            end
          end
        }
      end

      def initialize(parent)
        begin

          super(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_SUNKEN)
          #db_title = FXLabel.new(self, "DASHBOARD", :opts => LAYOUT_LEFT)
          @scanner = nil
          @progress_lock = Mutex.new

          main = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_GROOVE)
          main.backColor = FXColor::White

          frame = FXHorizontalFrame.new(main, :opts => LAYOUT_FILL_X|FRAME_GROOVE)
          frame.backColor = FXColor::White
          title_icon = FXButton.new(frame, '', ICON_DASHBOARD, :opts => FRAME_NONE)
          title_icon.backColor = FXColor::White


          @font_title = FXFont.new(getApp(), "helvetica", 14, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT)
          title = FXLabel.new(frame, "Dashboard", nil, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y)
          title.backColor = FXColor::White
          title.setFont(@font_title)
          title.justify = JUSTIFY_LEFT|JUSTIFY_CENTER_Y

          @tabBook = FXTabBook.new(main, nil, 0, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|LAYOUT_RIGHT)
          @tabBook.backColor = FXColor::White

          tab = FXTabItem.new(@tabBook, "Project Information", nil)
          # tab.backColor = FXColor::White
          @project_info_frame = ProjectInfo.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
          # @project_info_frame.backColor = FXColor::White
          tab = FXTabItem.new(@tabBook, "Scan Information", nil)
          # tab.backColor = FXColor::White

          @scan_progress_frame = ScanProgressFrame.new(@tabBook, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)

          @tabBook.connect(SEL_COMMAND) do |sender, sel, tabItem|

            case tabItem.to_i
              when 0
                #  puts "Login Script Selected"
                @project_info_frame.update()
              when 1
                # puts "Session IDs Selected"

              when 2
                #
            end
          end

          start_update_timer

        rescue => bang
          puts "Error creating dashboard :("
          puts bang
        end
      end
    end
  end
end
