class Cli
  class PushToProd < BookbinderCommand
    def run(arguments)
      app_dir = Dir.mktmpdir
      repository = GreenBuildRepository.new key: config.fetch('aws').fetch('access_key'),
                                            secret: config.fetch('aws').fetch('secret_key')

      repository.download download_dir: app_dir,
                          bucket: config.fetch('aws').fetch('green_builds_bucket'),
                          build_number: arguments[0],
                          namespace: Book.from_current_repo.short_name

      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow

      Pusher.new.push config.fetch('cloud_foundry').fetch('api_endpoint'),
                      config.fetch('cloud_foundry').fetch('production_host'),
                      config.fetch('cloud_foundry').fetch('organization'),
                      config.fetch('cloud_foundry').fetch('production_space'),
                      config.fetch('cloud_foundry').fetch('app_name'),
                      app_dir

      0
    end

    def usage
      "[build_#]"
    end
  end
end