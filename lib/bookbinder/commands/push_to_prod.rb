class Cli
  class PushToProd < BookbinderCommand
    def run(arguments)
      app_dir = Dir.mktmpdir

      aws_params = config.fetch('aws')
      repository = GreenBuildRepository.new key: aws_params.fetch('access_key'),
                                            secret: aws_params.fetch('secret_key')

      repository.download download_dir: app_dir,
                          bucket: aws_params.fetch('green_builds_bucket'),
                          build_number: arguments[0],
                          namespace: Book.new(full_name: config.fetch('github_repo')).short_name

      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow

      cf_params = config.fetch('cloud_foundry')
      Pusher.new.push cf_params.fetch('api_endpoint'),
                      cf_params.fetch('production_host'),
                      cf_params.fetch('organization'),
                      cf_params.fetch('production_space'),
                      cf_params.fetch('app_name'),
                      app_dir

      0
    end

    def usage
      "[build_#]"
    end
  end
end
