require_relative 'configuration'
require_relative 'yaml_loader'

module Bookbinder
  module Config
    class Fetcher
      def initialize(configuration_validator, loader, config_class)
        @loader = loader
        @configuration_validator = configuration_validator
        @config_class = config_class
      end

      def fetch_config
        @base_config ||= read_config_file
        @optional_configs ||= read_optional_configs

        @config ||= validate(@base_config, @optional_configs)
      end

      def set_config_dir_path(config_dir_path)
        @config_dir_path = File.expand_path(config_dir_path)
      end

      def set_config_file_path(config_file_path)
        @config_file_path = File.expand_path(config_file_path)
      end

      private

      attr_reader(:loader, :configuration_validator, :config, :config_file_path, :config_dir_path,
                  :config_class)

      def read_config_file
        loader.load(config_file_path)

      rescue FileNotFoundError => e
        raise "The configuration file specified does not exist. Please create a config #{e} file at #{config_file_path} and try again."
      rescue InvalidSyntaxError => e
        raise syntax_error(e)
      end

      def read_optional_configs
        Dir["#{config_dir_path}/*.yml"].map do |config_file|
          loader.load(File.expand_path(config_file)) || {}
        end.reduce({}, :merge)
      rescue InvalidSyntaxError => e
        raise syntax_error(e)
      end

      def validate(base_hash, optional_hash)
        raise 'Your config.yml appears to be empty. Please check and try again.' unless base_hash

        config_class.parse(base_hash.merge(optional_hash)).tap do |config|
          errors = configuration_validator.exceptions(config)
          raise errors.first if errors.any?
        end
      end

      def syntax_error(e)
        "There is a syntax error in your config file: \n #{e}"
      end
    end
  end
end
