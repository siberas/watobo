module Watobo

  def self.save_thread(&block)
    if FXApp.instance.respond_to? :runOnUiThread
      FXApp.instance.runOnUiThread &block
    else
      FXApp.instance.addChore &block
    end
  end

end