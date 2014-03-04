class Cli
  class PushToProd < BookbinderCommand
    def run(arguments)
      app_dir = Dir.mktmpdir

      bucket, key, secret = aws_credentials
      repository = GreenBuildRepository.new key: key, secret: secret

      repository.download download_dir: app_dir, bucket: bucket, build_number: arguments[0],
                          namespace: Book.new(full_name: config.book_repo).short_name

      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow

      Pusher.new.push *cf_credentials.push(app_dir)

      0
    end

    def cf_credentials
      [
        config.cf_credentials.api_endpoint,
        config.cf_credentials.production_host,
        config.cf_credentials.organization,
        config.cf_credentials.production_space,
        config.cf_credentials.app_name
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end

    def aws_credentials
      [
        config.aws_credentials.green_builds_bucket,
        config.aws_credentials.access_key,
        config.aws_credentials.secret_key
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end

    def self.usage
      '[build_#]'
    end
  end
end
