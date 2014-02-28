class Cli
  class PushToProd < BookbinderCommand
    include CommandRequiringCredentials

    def run(arguments)
      app_dir = Dir.mktmpdir

      bucket, key, secret = aws_credentials
      repository = GreenBuildRepository.new key: key, secret: secret

      repository.download download_dir: app_dir, bucket: bucket, build_number: arguments[0],
                          namespace: Book.new(full_name: config.fetch('book_repo')).short_name

      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow

      Pusher.new.push *cf_credentials.push(app_dir)

      0
    end

    def cf_credentials
      [
        config.fetch('cloud_foundry').fetch('api_endpoint'),
        config.fetch('cloud_foundry').fetch('production_host'),
        config.fetch('cloud_foundry').fetch('organization'),
        config.fetch('cloud_foundry').fetch('production_space'),
        config.fetch('cloud_foundry').fetch('app_name')
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end

    def aws_credentials
      [
        config.fetch('aws').fetch('green_builds_bucket'),
        config.fetch('aws').fetch('access_key'),
        config.fetch('aws').fetch('secret_key')
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end

    def usage
      "[build_#]"
    end
  end
end
