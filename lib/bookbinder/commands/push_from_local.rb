require_relative '../distributor'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushFromLocal
      include Commands::Naming

      def initialize(logger, configuration_fetcher, environment)
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @environment = environment
      end

      def usage
        [command_name,
         "Push the contents of final_app to the #{environment} host specified in credentials.yml"]
      end

      def run(_)
        Distributor.build(@logger, options).distribute
        0
      end

      private

      attr_reader :configuration_fetcher, :environment

      def config
        @config ||= configuration_fetcher.fetch_config
      end

      def command_name
        "push_local_to_#{environment}"
      end

      def options
        {
            app_dir: './final_app',
            build_number: ENV['BUILD_NUMBER'],

            aws_credentials: config.aws_credentials,
            cf_credentials: config.cf_credentials(environment),

            book_repo: config.book_repo,
        }
      end
    end
  end
end
