module Bookbinder
  class Cli
    class RunPublishCI < BookbinderCommand
      def run(cli_args)
        check_params
        all_successfully_ran = publish(cli_args) == 0 && push_to_staging == 0 && push_tarball == 0
        all_successfully_ran ? 0 : 1
      end

      def self.usage
        ''
      end

      private

      def check_params
        raise BuildAndPushTarball::MissingBuildNumber unless ENV['BUILD_NUMBER']
        config.book_repo
      end

      def publish(cli_args)
        Publish.new(@logger, config).run(['github'] + cli_args)
      end

      def push_to_staging
        PushLocalToStaging.new(@logger, config).run []
      end

      def push_tarball
        BuildAndPushTarball.new(@logger, config).run []
      end
    end
  end
end