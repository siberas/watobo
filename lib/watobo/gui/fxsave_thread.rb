module Watobo
  def self.save_thread(ms=250, &block)
    FXApp.instance.addTimeout(ms, :repeat => true, &block)
  end

  def self.save_thread_UNUSED(ms=250, &block)
    Thread.new {
      loop do
        sleep 0.5
        Watobo::Gui.application.runOnUiThread(&block)
      end
    }
  end
end