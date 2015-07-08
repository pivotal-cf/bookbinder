require_relative '../deploy/deployment'
require_relative '../deploy/distributor'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushToProd
      include Commands::Naming
      MissingRequiredKeyError = Class.new(RuntimeError)

      def initialize(streams, logger, configuration_fetcher, app_dir)
        @streams = streams
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @app_dir = app_dir
      end

      def usage
        ["push_to_prod [build_#]",
         "Push latest or <build_#> from your S3 bucket to the production host specified in credentials.yml"]
      end

      def run((build_number))
        streams[:warn].puts "Warning: You are pushing to production."
        validate
        Deploy::Distributor.build(
          @logger,
          Deploy::Deployment.new(
            app_dir: app_dir,
            build_number: build_number,
            aws_credentials: credentials[:aws],
            cf_credentials: credentials[:cloud_foundry],
            book_repo: config.book_repo,
          )
        ).distribute
        0
      end

      private

      attr_reader :app_dir, :configuration_fetcher, :streams

      def credentials
        configuration_fetcher.fetch_credentials('production')
      end

      def config
        configuration_fetcher.fetch_config
      end

      def validate
        unless config.has_option?('cred_repo')
          raise MissingRequiredKeyError.new "Your config.yml is missing required key(s). The require keys for this commands are cred_repo"
        end
      end
    end
  end
end
