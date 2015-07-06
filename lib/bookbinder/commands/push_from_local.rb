require_relative '../deploy/distributor'
require_relative 'bookbinder_command'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushFromLocal
      include Commands::Naming

      CredentialKeyError = Class.new(RuntimeError)
      REQUIRED_AWS_KEYS = %w(access_key secret_key green_builds_bucket)
      REQUIRED_CF_KEYS = %w(username password api_endpoint organization app_name)

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
        validate
        Deploy::Distributor.build(@logger, options).distribute
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
        credentials = configuration_fetcher.fetch_credentials(environment)
        {
            app_dir: './final_app',
            build_number: ENV['BUILD_NUMBER'],

            aws_credentials: credentials[:aws],
            cf_credentials: credentials[:cloud_foundry],

            book_repo: config.book_repo,
        }
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
