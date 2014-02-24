class Cli
  class PushLocalToStaging < BookbinderCommand
    include CommandRequiringCredentials

    def run(_)
      Pusher.new.push *cf_credentials
      0
    end

    private

    def cf_credentials
      [
        config.fetch('cloud_foundry').fetch('api_endpoint'),
        config.fetch('cloud_foundry').fetch('staging_host'),
        config.fetch('cloud_foundry').fetch('organization'),
        config.fetch('cloud_foundry').fetch('staging_space'),
        config.fetch('cloud_foundry').fetch('app_name'),
        './final_app',
        config.fetch('cloud_foundry').fetch('username'),
        config.fetch('cloud_foundry').fetch('password')
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end
  end
end
