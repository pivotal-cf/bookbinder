class Cli
  class BuildAndPushTarball < BookbinderCommand
    include CommandRequiringCredentials

    class MissingBuildNumber < StandardError
      def initialize
        super 'You must set $BUILD_NUMBER to push an identifiable build.'
      end
    end

    def child_run(_)
      raise MissingBuildNumber unless ENV['BUILD_NUMBER']
      bucket, key, secret = aws_credentials
      repository = GreenBuildRepository.new key: key, secret: secret
      repository.create build_number: ENV['BUILD_NUMBER'], bucket: bucket,
                        namespace: Book.new(full_name: config.fetch('book_repo')).short_name
      0
    end

    private

    def aws_credentials
      [
        config.fetch('aws').fetch('green_builds_bucket'),
        config.fetch('aws').fetch('access_key'),
        config.fetch('aws').fetch('secret_key')
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end
  end
end
