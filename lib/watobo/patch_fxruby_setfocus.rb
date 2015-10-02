# Work around error 'FXComposeContext: illegal window parameter'
# in FXWindow#setFocus of some libfox versions.

class Fox::FXWindow
  def setFocus
    app.addChore do
      super
    end
  end
end

class Fox::FXDialogBox
  def setFocus
    app.addChore do
      super
    end
  end
end

class Fox::FXTextField
  def setFocus
    app.addChore do
      super
    end
  end
end

