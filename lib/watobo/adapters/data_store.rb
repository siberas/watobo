# @private 
module Watobo#:nodoc: all
  class DataStore
    
    @engine = nil
    
    def self.engine
      @engine
    end
    
    def self.projects(&block)
      ps = []
       Dir.glob("#{Watobo.workspace_path}/*").each do |p|
         pname = File.basename(p)
         yield pname if block_given?
         ps << pname
       end
       ps
    end
    
    def self.sessions(project_name, &block)
      ss = []
      project_name = project_name.to_s if project_name.is_a? Symbol
      return ps unless File.exist? "#{Watobo.workspace_path}/#{project_name}"
       Dir.glob("#{Watobo.workspace_path}/#{project_name}/*").each do |s|
         sname = File.basename(s)
         yield sname if block_given?
         ss << sname
       end
       ss
    end    
      
    def self.connect(project_name, session_name)
      a = Watobo::Conf::Datastore.adapter
      store = case
      when 'file'
        FileSessionStore.new(project_name, session_name)
      else
        nil
      end
      @engine = store
      store
    end
    
    def self.method_missing(name, *args, &block)
      super unless @engine.respond_to? name
      @engine.send name, *args, &block
    end
    
        
  end
  
  def self.logs
    return "" if DataStore.engine.nil?
    DataStore.engine.logs
  end
  
  def self.log(message, prefs={})
    
    text = message
    if message.is_a? Array
      text = message.join("\n| ")
    end
    
    #clean up sender's name
    if prefs.has_key? :sender
      prefs[:sender].gsub!(/.*::/,'')
    end
    
    if DataStore.engine.respond_to? :logger
      DataStore.engine.logger message, prefs
    end
  end
end