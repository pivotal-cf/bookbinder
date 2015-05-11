require_relative 'bind'
require_relative 'build_and_push_tarball'
require_relative 'chain'
require_relative 'naming'
require_relative 'push_from_local'

module Bookbinder
  module Commands
    class RunPublishCI
      include Commands::Naming
      include Commands::Chain

      def usage
        [command_name,
         "Run publish, push_local_to_staging, and build_and_push_tarball for CI purposes"]
      end

      def initialize(publish_command, push_local_to_staging_command, build_and_push_tarball_command)
        @publish_command = publish_command
        @push_local_to_staging_command = push_local_to_staging_command
        @build_and_push_tarball_command = build_and_push_tarball_command
      end

      def run(cli_args)
        raise BuildAndPushTarball::MissingBuildNumber unless ENV['BUILD_NUMBER']

        command_chain(
          ->{publish_command.run(['remote'] + cli_args)},
          ->{push_local_to_staging_command.run([])},
          ->{build_and_push_tarball_command.run([])}
        )
      end

      private

      attr_reader :publish_command, :push_local_to_staging_command, :build_and_push_tarball_command
    end
  end
end
