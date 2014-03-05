class Cli
  class PushToProd < BookbinderCommand
    def run(arguments)
      app_dir = Dir.mktmpdir

      bucket = config.aws_credentials.green_builds_bucket
      key = config.aws_credentials.access_key
      secret = config.aws_credentials.secret_key

      repository = GreenBuildRepository.new key: key, secret: secret

      repository.download download_dir: app_dir, bucket: bucket, build_number: arguments[0],
                          namespace: Book.new(full_name: config.book_repo).short_name

      log 'Warning: You are pushing to CF Docs production. Be careful.'.yellow

      cf_command_runner = CfCommandRunner.new(config.cf_production_credentials)
      Pusher.new(cf_command_runner).push(app_dir)

      0
    end

    def self.usage
      '[build_#]'
    end
  end
end
