module Watobo #:nodoc: all
  module Gui
    class KmeansClustererFrame < FXVerticalFrame

      attr :chats

      include Watobo::Subscriber

      def set_chats(chats)
        @chats = chats
        kmeans_update
        update_cluster_matrix
      end


      def kmeans_update(settings = @settings.to_h)
        @kmeans = Watobo::Ml::KmeansChats.new @chats
        @kmeans.run settings
      end


      def update_cluster_matrix

        @settings.selection = {}

        begin
          @clusters_matrix.each_child do |child|
            @clusters_matrix.removeChild(child)
          end

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
        defaults = {num_clusters: 15}
        @settings = OpenStruct.new defaults
        @kmeans = nil

        @chats = []
        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | FRAME_RAISED, :padding => 0) #| FRAME_GROOVE)
        FXLabel.new(frame, "K-Means Filter")


        frame = FXHorizontalFrame.new(self, :opts => LAYOUT_FILL_X | FRAME_SUNKEN, :padding => 0, :hSpacing => 0, :vSpacing => 0) #| FRAME_GROOVE)

        FXLabel.new(frame, "#clusters", :opts => FRAME_SUNKEN)
        @clusters_num = FXTextField.new(frame, 5, nil, 0, FRAME_SUNKEN | FRAME_THICK | LAYOUT_FILL_X)
        @clusters_num.text = @settings.num_clusters.to_s

        @pbar = FXProgressBar.new(self, nil, 0, LAYOUT_FILL_X | FRAME_SUNKEN | FRAME_THICK | PROGRESSBAR_HORIZONTAL)

        @pbar.progress = 0
        @pbar.total = 0
        @pbar.barColor = 'grey' #FXRGB(255,0,0)


        scroller = FXScrollWindow.new(self, SCROLLERS_NORMAL | LAYOUT_FILL_X | LAYOUT_FILL_Y)
        @clusters_matrix = FXMatrix.new(scroller, 5, :opts => MATRIX_BY_COLUMNS | LAYOUT_FILL_X | LAYOUT_FILL_Y, :padding => 0)
        @clusters_matrix.backColor = FXColor::White


      end

      private

      def update_settings
        @settings.num_clusters = @clusters_num.text.to_i
      end

      def progress(inc)
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


    end
  end
end
