class Cli
  class PushLocalToStaging < BookbinderCommand
    def run(_)
      Pusher.new.push *cf_credentials
      0
    end

    def self.usage
      ''
    end

    private

    def cf_credentials
      [
        config.cf_credentials.api_endpoint,
        config.cf_credentials.staging_host,
        config.cf_credentials.organization,
        config.cf_credentials.staging_space,
        config.cf_credentials.app_name,
        './final_app',
        config.cf_credentials.username,
        config.cf_credentials.password
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end
  end
end
