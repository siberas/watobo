module Watobo
  class Server

    def crawl(url)
      request = Watobo::Request.new url
      project = request.host
      session = 'crawl' + Time.now.to_i.to_s

      Watobo.create_project project_name: project, session_name: session

      binding.pry
    end

    def initialize(workspace)
      Watobo.workspace_path = workspace
      Watobo.init_framework
    end

  end
end