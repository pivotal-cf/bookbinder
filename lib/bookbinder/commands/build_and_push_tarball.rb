class Cli
  class BuildAndPushTarball < BookbinderCommand
    class MissingBuildNumber < StandardError
      def initialize
        super 'You must set $BUILD_NUMBER to push an identifiable build.'
      end
    end

    def run(_)
      raise MissingBuildNumber unless ENV['BUILD_NUMBER']

      repository = GreenBuildRepository.new key: config.fetch('aws')['access_key'],
                                            secret: config.fetch('aws')['secret_key']

      repository.create build_number: ENV['BUILD_NUMBER'],
                        bucket: config.fetch('aws')['green_builds_bucket'],
                        namespace: Book.new(full_name: config.fetch('github_repo')).short_name
      0
    end
  end
end
