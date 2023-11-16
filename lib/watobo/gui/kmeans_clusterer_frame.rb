module Watobo #:nodoc: all
  module Gui
    class KmeansClustererFrame < FXVerticalFrame

      attr :chats

      include Watobo::Subscriber

      def set_chats(chats)
        @chats = chats
        # kmeans_update
        clear_cluster_buttons
        #update_cluster_matrix
      end


      def kmeans_update(settings = @settings.to_h)
        @kmeans = Watobo::Ml::KmeansChats.new @chats
        progress_subscribtions(@kmeans)
        run_kmeans(settings)
      end


      def update_cluster_matrix

        @settings.selection = {}

        begin
          clear_cluster_buttons

          @kmeans.clusters.each do |cluster|
            txt = "#{cluster.points.length} (#{cluster.id})"
            pbtn = FXToggleButton.new(@clusters_matrix, txt, txt, nil, nil, nil, 0, :opts => LAYOUT_FILL_COLUMN | FRAME_RAISED | FRAME_THICK | TOGGLEBUTTON_KEEPSTATE | LAYOUT_FILL_X)
            pbtn.create

            pbtn.connect(SEL_COMMAND) { |sender, sel, cmd|
              @settings.selection[cluster.id] = sender.state
              update_settings
              update_table
            }

          end

          @clusters_matrix.recalc
          @clusters_matrix.update

        rescue => bang
          puts bang
          puts bang.backtrace if $DEBUG
        end
      end


      def initialize(owner, prefs)
        super(owner, prefs)
        defaults = {
            num_clusters: 15,
            runs: 10
        }
        @settings = OpenStruct.new defaults
        @kmeans = nil
        @progress = {}
        @progress_lock = Mutex.new
        @kmeans_thread = nil

        @chats = []
        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | FRAME_RAISED, :padding => 0) #| FRAME_GROOVE)
        FXLabel.new(frame, "ML Filter (K-Means)")


        hframe = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)
        vframe_l = FXVerticalFrame.new(hframe, :opts => FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)
        vframe_r = FXVerticalFrame.new(hframe, :opts => LAYOUT_FILL_X | LAYOUT_FILL_Y | FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)

        c_frame = FXHorizontalFrame.new(vframe_l, :opts => LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)

        FXLabel.new(c_frame, "#clusters", :opts => FRAME_SUNKEN | LAYOUT_FIX_WIDTH, :width => 80)
        @clusters_num = FXTextField.new(c_frame, 5, nil, 0, FRAME_SUNKEN | FRAME_THICK | LAYOUT_FIX_WIDTH, :width => 40)
        @clusters_num.text = @settings.num_clusters.to_s

        r_frame = FXHorizontalFrame.new(vframe_l, :opts => LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)

        FXLabel.new(r_frame, "#runs", :opts => FRAME_SUNKEN | LAYOUT_FIX_WIDTH, :width => 80)
        @runs_num = FXTextField.new(r_frame, 5, nil, 0, FRAME_SUNKEN | FRAME_THICK | LAYOUT_FIX_WIDTH, :width => 40)
        @runs_num.text = @settings.runs.to_s

        @update_btn = FXButton.new(vframe_r, "Update", nil, nil, :opts => BUTTON_NORMAL | LAYOUT_RIGHT | LAYOUT_FILL_Y | LAYOUT_FILL_X | LAYOUT_MIN_WIDTH, :width => 180)
        @update_btn.connect(SEL_COMMAND) { kmeans_update }


        @pbar = FXProgressBar.new(self, nil, 0, LAYOUT_FILL_X | FRAME_SUNKEN | FRAME_THICK | PROGRESSBAR_HORIZONTAL)

        @pbar.progress = 0
        @pbar.total = 0
        @pbar.barColor = 'grey' #FXRGB(255,0,0)


        scroller = FXScrollWindow.new(self, SCROLLERS_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_Y)
        @clusters_matrix = FXMatrix.new(scroller, 3, :opts => MATRIX_BY_COLUMNS | LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
        @clusters_matrix.backColor = FXColor::White


      end

      private

      def run_kmeans(settings)
        if @kmeans
          clear_cluster_buttons
          reset_progress_bar
          start_update_timer
          @kmeans_thread = Thread.new {
            @kmeans.run settings, true
          }
        end
      end

      # @param target [object] supporting module Subscriber
      # the target should notify :progress with the following data
      # {
      #    total: < total number of steps >,
      #    progress: < current progress >,
      #    status: < :idle | :running | :finished >
      # }
      def progress_subscribtions(target)
        return false unless target.respond_to? :subscribe
        target.subscribe(:progress) do |p|
          @progress_lock.synchronize do
            @progress.update p
          end
        end
      end


      def update_settings
        @settings.num_clusters = @clusters_num.text.to_i
        @settings.runs = @runs_num.text.to_i
        @settings
      end

      def update_clusters(settings = update_settings.to_h)
        run_kmeans(settings)
      end

      def clear_cluster_buttons
        @clusters_matrix.each_child do |child|
          @clusters_matrix.removeChild(child)
        end
        @clusters_matrix.handle(self, FXSEL(SEL_UPDATE, 0), nil)

      end

      def reset_progress_bar
        @pbar.barColor = 'red' #FXRGB(255,0,0)
        @pbar.progress = 0
        @pbar.handle(self, FXSEL(SEL_UPDATE, 0), nil)
      end


      def enable_cluster_buttons
        @clusters_matrix.each_child do |child|
          child.enabled = true
        end
      end

      def disable_cluster_buttons
        @clusters_matrix.each_child do |child|
          child.enabled = false
        end
      end

      def update_table
        chats = []
        @settings.selection.each do |cluster_id, state|
          if state
            chats.concat @kmeans.chats_of_cluster(cluster_id)
          end
        end
        notify(:show_chats, chats)
      end

      def start_update_timer(interval = 1500)

        @timer = FXApp.instance.addTimeout(interval, :repeat => true) {
          #print '*'
          progress = {}
          @progress_lock.synchronize do
            progress = @progress.clone
          end

          case progress[:status]
          when :idle
            @pbar.barColor = 'grey' #FXRGB(255,0,0)
          when :running
            @pbar.barColor = 'red' #FXRGB(255,0,0)
            @pbar.total = progress[:total]
            @pbar.progress = progress[:progress]
            disable_cluster_buttons
          when :finished
            FXApp.instance.addTimeout(interval / 2) {
              FXApp.instance.removeTimeout(@timer)
            }
            @pbar.barColor = 'green' #FXRGB(255,0,0)
            @pbar.progress = @pbar.total
            @pbar.handle(self, FXSEL(SEL_UPDATE, 0), nil)

            update_cluster_matrix


            #enable_cluster_buttons
            # binding.pry

          end
        }
      end

    end
  end
end
