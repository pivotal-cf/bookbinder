require_relative '../deploy/deployment'
require_relative '../deploy/distributor'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushFromLocal
      include Commands::Naming

      CredentialKeyError = Class.new(RuntimeError)
      REQUIRED_AWS_KEYS = %w(access_key secret_key green_builds_bucket)
      REQUIRED_CF_KEYS = %w(username password api_endpoint organization app_name)

      def initialize(streams, logger, configuration_fetcher, environment)
        @streams = streams
        @logger = logger
        @configuration_fetcher = configuration_fetcher
        @environment = environment
      end

      def usage
        [command_name,
         "Push the contents of final_app to the #{environment} host specified in credentials.yml"]
      end

      def run(_)
        validate
        deployment = Deploy::Deployment.new(
          app_dir: './final_app',
          aws_credentials: credentials[:aws],
          book_repo: config.book_repo,
          build_number: ENV['BUILD_NUMBER'],
          cf_credentials: credentials[:cloud_foundry]
        )
        archive = Deploy::Archive.new(
          logger: @logger,
          key: deployment.aws_access_key,
          secret: deployment.aws_secret_key
        )
        Deploy::Distributor.build(
          streams,
          archive,
          deployment
        ).distribute
        0
      end

      private

      attr_reader :configuration_fetcher, :environment, :streams

      def config
        configuration_fetcher.fetch_config
      end

      def credentials
        configuration_fetcher.fetch_credentials(environment)
      end

      def command_name
        "push_local_to_#{environment}"
      end

      def error_message
        <<-ERROR
Cannot locate a specific key in credentials.yml.
Your credentials file should follow this format:

aws:
  access_key: <your_AWS_access_key>
  secret_key: <your_AWS_secret_key>
  green_builds_bucket: <your_AWS_bucket>

cloud_foundry:
  username: <your_CF_account>
  password: <your_CF_password>
  staging_space: <your_CF_staging_space_name>
  staging_host: <your_CF_staging_host_name>
    <your-domain.com>:
      - <your_hostname>
  production_space: <your_CF_production_space_name>
  production_host: <your_CF_production_host_name>
    <your-domain.com>:
      - <your_hostname>
  app_name: <your_app_name>
  api_endpoint: <your_api_endpoint>
  organization: <your_organization>
        ERROR
      end

      def validate
        missing_keys = []

        creds = configuration_fetcher.fetch_credentials(environment)
        aws_creds = creds[:aws]
        cf_creds = creds[:cloud_foundry]

        missing_keys << 'aws' unless aws_creds
        missing_keys << 'cloud_foundry' unless cf_creds

        REQUIRED_AWS_KEYS.map do |key|
          missing_keys << key unless aws_creds.send(key)
        end

        REQUIRED_CF_KEYS.each do |key|
          missing_keys << key unless cf_creds.send(key)
        end

        raise CredentialKeyError.new error_message if missing_keys.any?
      end
    end
  end
end
