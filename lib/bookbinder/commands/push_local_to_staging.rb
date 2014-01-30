class Cli
  class PushLocalToStaging < BookbinderCommand
    def run(_)
      Pusher.new.push config.fetch('cloud_foundry').fetch('api_endpoint'),
                      config.fetch('cloud_foundry').fetch('staging_host'),
                      config.fetch('cloud_foundry').fetch('organization'),
                      config.fetch('cloud_foundry').fetch('staging_space'),
                      config.fetch('cloud_foundry').fetch('app_name'),
                      './final_app',
                      config.fetch('cloud_foundry').fetch('username'),
                      config.fetch('cloud_foundry').fetch('password')
      0
    end
  end
end
