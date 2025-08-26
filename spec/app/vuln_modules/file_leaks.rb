class VulnApp < Sinatra::Base

  @@appsettings =  {
    "Logging": {
      "LogLevel": {
        "Default": "Information",
        "Microsoft": "Warning"
      }
    },
    "ConnectionStrings": {
      "DefaultConnection": "Server=myserver;Database=mydb;User Id=admin;Password=secret123;"
    },
    "FeatureToggle": {
      "EnableCoolFeature": true
    }
  }

  # curl -i http://127.0.0.1:9292/leaks/appsettings.json
  get '/leaks/appsettings.json' do
    headers "Content-Type" => "application/json"
    # without session, no cookie will be set
    session[:foo] = :howdy
    @@appsettings.to_json
  end

  # simulate 403 Forbidden for protected folder
  # curl -i "http://127.0.0.1:9292/leaks/protected/appsettings.json"
  #
   get '/leaks/protected/*' do
     403
   end

  # Protected path to appsettings.json
  # Should be found by filescanner with evasions enabled
  # curl -i "http://127.0.0.1:9292/leaks/protected;/appsettings.json"
  get '/leaks/protected;/appsettings.json' do
    headers "Content-Type" => "application/json"

   @@appsettings.to_json
  end

  get '/leaks/odata' do
    headers "Content-Type" => "application/json"

    {
  "@odata.context": "https://127.0.0.1/api/odata/$metadata",
  "value": [
    {
      "name": "FeedbackOData",
      "kind": "EntitySet",
      "url": "FeedbackOData"
    },
    {
      "name": "SessionOData",
      "kind": "EntitySet",
      "url": "SessionOData"
    },
    {
      "name": "ExplorationOData",
      "kind": "EntitySet",
      "url": "ExplorationOData"
    }
  ]
}.to_json
  end
end
