# @private 
module Watobo#:nodoc: all
  def self.load_chat(project, session, chat_id)
    path = File.join Watobo.workspace_path, project.to_s, session.to_s, Watobo::Conf::Datastore.conversations
    unless File.exist? path
      puts "Could not find conversation path for #{project}/#{session} in #{Watobo.workspace_path}"
      return nil
    end
    chat_file = "#{chat_id}-chat.yml"
    chat = Watobo::Utils.loadChatYAML File.join(path, chat_file)
    puts chat.class
    chat
    
  end
end