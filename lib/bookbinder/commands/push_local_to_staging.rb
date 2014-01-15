class Cli
  class PushLocalToStaging < BookbinderCommand
    def run(_)
      Pusher.new.push config['cloud_foundry']['api_endpoint'],
                      config['cloud_foundry']['staging_host'],
                      config['cloud_foundry']['organization'],
                      config['cloud_foundry']['staging_space'],
                      config['cloud_foundry']['app_name'],
                      './final_app',
                      config['cloud_foundry']['username'],
                      config['cloud_foundry']['password']
      0
    end
  end
end
