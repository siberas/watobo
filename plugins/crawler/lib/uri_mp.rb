module URI
  def site
    "#{self.host}:#{self.port}"
  end
  
  # path ( Monkey Patched )
  def path_mp
    #p = self.path
    self.path.gsub(/\/[^\/]*$/,'/')
    
  end
end
