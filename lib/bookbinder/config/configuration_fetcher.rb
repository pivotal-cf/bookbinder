require_relative 'aws_credentials'
require_relative 'cf_credentials'
require_relative 'configuration'
require_relative '../yaml_loader'

module Bookbinder
  module Config
    class ConfigurationFetcher
      def initialize(logger, configuration_validator, loader, credentials_provider)
        @loader = loader
        @logger = logger
        @configuration_validator = configuration_validator
        @credentials_provider = credentials_provider
      end

      def fetch_config
        @config ||= validate(read_config_file)
      end

      def fetch_credentials(environment = 'null-environment')
        @credentials ||= credentials_provider.credentials(fetch_config.cred_repo_url)
        {
          aws: Config::AwsCredentials.new(
            @credentials.fetch('aws', {})
          ),
          cloud_foundry: Config::CfCredentials.new(
            @credentials.fetch('cloud_foundry', {}),
            environment
          )
        }
      end

      def set_config_file_path config_file_path
        @config_file_path = File.expand_path config_file_path
      end

      private

      attr_reader(:loader, :logger, :configuration_validator, :config, :config_file_path,
                  :credentials_provider)

      def read_config_file
        loader.load(config_file_path)

      rescue FileNotFoundError => e
        raise "The configuration file specified does not exist. Please create a config #{e} file at #{config_file_path} and try again."
      rescue InvalidSyntaxError => e
        raise "There is a syntax error in your config file: \n #{e}"
      end

      def validate(config_hash)
        raise 'Your config.yml appears to be empty. Please check and try again.' unless config_hash

        errors = configuration_validator.exceptions(config_hash)
        raise errors.first if errors.any?

        Configuration.parse(config_hash)
      end
    end
  end
end
