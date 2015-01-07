require_relative 'bookbinder_command'
require_relative 'naming'
require_relative 'publish'
require_relative 'push_local_to_staging'
require_relative 'build_and_push_tarball'

module Bookbinder
  module Commands
    class RunPublishCI < BookbinderCommand
      extend Commands::Naming

      def self.usage
        "run_publish_ci \t \t \t \t Run publish, push_local_to_staging, and build_and_push_tarball for CI purposes"
      end

      def run(cli_args)
        check_params
        all_successfully_ran = publish(cli_args) == 0 && push_to_staging == 0 && push_tarball == 0
        all_successfully_ran ? 0 : 1
      end

      private

      def check_params
        raise BuildAndPushTarball::MissingBuildNumber unless ENV['BUILD_NUMBER']
        config.book_repo
      end

      def publish(cli_args)
        Publish.new(@logger, @configuration_fetcher).run(['github'] + cli_args)
      end

      def push_to_staging
        PushLocalToStaging.new(@logger, @configuration_fetcher).run []
      end

      def push_tarball
        BuildAndPushTarball.new(@logger, @configuration_fetcher).run []
      end
    end
  end
end
