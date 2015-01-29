require_relative 'bookbinder_command'
require_relative 'naming'
require_relative 'publish'
require_relative 'push_local_to_staging'
require_relative 'build_and_push_tarball'

module Bookbinder
  module Commands
    class RunPublishCI
      include Commands::Naming

      def usage
        "run_publish_ci \t \t \t \t Run publish, push_local_to_staging, and build_and_push_tarball for CI purposes"
      end

      def initialize(publish_command, push_local_to_staging_command, build_and_push_tarball_command)
        @publish_command = publish_command
        @push_local_to_staging_command = push_local_to_staging_command
        @build_and_push_tarball_command = build_and_push_tarball_command
      end

      def run(cli_args)
        raise BuildAndPushTarball::MissingBuildNumber unless ENV['BUILD_NUMBER']

        all_successfully_ran =
            publish_command.run(['github'] + cli_args) == 0 &&
            push_local_to_staging_command.run([]) == 0 &&
            build_and_push_tarball_command.run([]) == 0

        all_successfully_ran ? 0 : 1
      end

      private

      attr_reader :publish_command, :push_local_to_staging_command, :build_and_push_tarball_command
    end
  end
end
