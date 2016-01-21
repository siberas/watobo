# @private 
module Watobo #:nodoc: all
  module Gui
    class ProgressWindow < FXTopWindow
      def increment(x)
        @update_lock.synchronize do
          @increment += x
        end
      end

      def total=(x)
        @update_lock.synchronize do
          @total = x
        end
      end

      def UNUSED_progress=(x)
        @pbar.progress = x
      end

      def title=(new_title)
        @update_lock.synchronize do
          @title = new_title
        end
      end

      def task=(new_task)
        @update_lock.synchronize do
          @task = new_task
        end
      end

      def job=(new_job)
        @update_lock.synchronize do
          @job = new_job
        end
      end

      def update_progress(settings={})
        @total = settings[:total] unless settings[:total].nil?
        @title = settings[:title] unless settings[:title].nil?
        @task = settings[:task] unless settings[:task].nil?
        @job = settings[:job] unless settings[:job].nil?
        @increment += settings[:increment] unless settings[:increment].nil?

        Watobo::Gui.application.runOnUiThread do
          @title_lbl.text = @title
          @task_lbl.text = @task
          @job_lbl.text = @job

          @pbar.increment(@increment)
          @increment = 0
          @pbar.total = @total
        end
      end

      def initialize(owner, opts={})
        super(owner, 'Progress Bar', nil, nil, DECOR_BORDER, 0, 0, 300, 100, 0, 0, 0, 0, 0, 0)
        frame = FXVerticalFrame.new(self, :opts => LAYOUT_FILL_X|LAYOUT_FILL_Y|FRAME_RAISED)
        @update_lock = Mutex.new

        @title_lbl = FXLabel.new(frame, "title")
        @title_lbl.setFont(FXFont.new(getApp(), "helvetica", 12, FONTWEIGHT_BOLD, FONTSLANT_ITALIC, FONTENCODING_DEFAULT))

        @task_lbl = FXLabel.new(frame, "task")

        @pbar = FXProgressBar.new(frame, nil, 0, LAYOUT_FILL_X|FRAME_SUNKEN|FRAME_THICK|PROGRESSBAR_HORIZONTAL)

        @job_lbl = FXLabel.new(frame, "job")

        @pbar.progress = 0
        @pbar.total = 100
        @increment = 0
        @total = 100
        @title = "-"
        @job = "-"
        @task = "-"

          #add_update_timer(50)
      end

      # TODO: remove if unused
      def add_update_timer_UNUSED(ms)
        @update_timer = FXApp.instance.addTimeout(ms, :repeat => true) {
          @update_lock.synchronize do
            @title_lbl.text = @title
            @task_lbl.text = @task
            @job_lbl.text = @job

            @pbar.increment(@increment)
            @increment = 0
            @pbar.total = @total
            # @pbar.progress = settings[:progress] unless settings[:progress].nil?
          end
        }
      end

    end

  end
end
