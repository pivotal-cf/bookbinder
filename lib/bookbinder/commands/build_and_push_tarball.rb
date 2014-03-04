class Cli
  class BuildAndPushTarball < BookbinderCommand
    class MissingBuildNumber < StandardError
      def initialize
        super 'You must set $BUILD_NUMBER to push an identifiable build.'
      end
    end

    def run(_)
      raise MissingBuildNumber unless ENV['BUILD_NUMBER']
      bucket, key, secret = aws_credentials
      repository = GreenBuildRepository.new key: key, secret: secret
      repository.create build_number: ENV['BUILD_NUMBER'], bucket: bucket,
                        namespace: Book.new(full_name: config.book_repo).short_name
      0
    end

    def self.usage
      ''
    end

    private

    def aws_credentials
      [
        config.aws_credentials.green_builds_bucket,
        config.aws_credentials.access_key,
        config.aws_credentials.secret_key
      ]
    rescue KeyError => e
      raise CredentialKeyError, e
    end
  end
end
