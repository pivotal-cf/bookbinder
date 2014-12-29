module Bookbinder
  class Cli
    class BuildAndPushTarball < BookbinderCommand
      class MissingBuildNumber < StandardError
        def initialize
          super 'You must set $BUILD_NUMBER to push an identifiable build.'
        end
      end

      def run(_)
        raise MissingBuildNumber unless ENV['BUILD_NUMBER']
        config = configuration_fetcher.fetch_config
        aws_credentials = config.aws_credentials
        repository = Archive.new(logger: @logger, key: aws_credentials.access_key, secret: aws_credentials.secret_key)
        repository.create_and_upload_tarball(build_number: ENV['BUILD_NUMBER'], bucket: aws_credentials.green_builds_bucket,
                                             namespace: GitHubRepository.new(logger: @logger, full_name: config.book_repo).short_name)
        0
      end

      def self.usage
        ''
      end
    end
  end
end
