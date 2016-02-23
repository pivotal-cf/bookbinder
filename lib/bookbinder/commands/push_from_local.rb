require_relative '../deploy/deployment'
require_relative '../deploy/distributor'
require_relative 'naming'

module Bookbinder
  module Commands
    class PushFromLocal
      include Commands::Naming

      CredentialKeyError = Class.new(RuntimeError)
      FeedbackConfigError = Class.new(RuntimeError)
      REQUIRED_AWS_KEYS = %w(access_key secret_key green_builds_bucket)
      REQUIRED_CF_KEYS = %w(username password api_endpoint organization app_name)

      def initialize(streams, logger, configuration_fetcher)
        @streams = streams
        @logger = logger
        @configuration_fetcher = configuration_fetcher
      end

      def usage
        ["push_local_to <environment>",
         "Push the contents of final_app to the specified environment using the credentials.yml"]
      end

      def run(cli_arguments)
        @environment = cli_arguments.first
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

      def command_name
        'push_local_to'
      end

      def config
        configuration_fetcher.fetch_config
      end

      def credentials
        configuration_fetcher.fetch_credentials(environment)
      end

      def creds_error_message
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

      def mail_error_message
        <<-ERROR
Your environment variables for sending feedback are not set.

To enable feedback, you must set the following variables in your environment:

export SENDGRID_USERNAME=<your-username>
export SENDGRID_API_KEY=<your-api-key>
export FEEDBACK_TO=<email-to-receive-feedback>
export FEEDBACK_FROM=<email-to-send-feedback>
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

        raise CredentialKeyError.new(creds_error_message) if missing_keys.any?
        raise FeedbackConfigError.new(mail_error_message) if config.feedback_enabled && mail_vars_absent?
      end

      def mail_vars_absent?
        !(ENV['SENDGRID_USERNAME'] && ENV['SENDGRID_API_KEY'] && ENV['FEEDBACK_TO'] && ENV['FEEDBACK_FROM'])
      end
    end
  end
end
