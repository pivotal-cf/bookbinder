require_relative 'configuration'
require_relative 'yaml_loader'

module Bookbinder
  class ConfigurationFetcher
    def initialize(logger, configuration_validator, loader)
      @loader = loader
      @logger = logger
      @configuration_validator = configuration_validator
    end

    def fetch_config
      @config ||= validate(read_config_file)
    end

    def set_config_file_path config_file_path
      @config_file_path = File.expand_path config_file_path
    end

    private

    attr_reader(:loader, :logger, :configuration_validator, :config, :config_file_path)

    def read_config_file
      loader.load(config_file_path).merge('pdf_index' => nil)

    rescue FileNotFoundError => e
      raise "The configuration file specified does not exist. Please create a config #{e} file at #{config_file_path} and try again."
    rescue InvalidSyntaxError => e
      raise "There is a syntax error in your config file: \n #{e}"
    end

    def validate(config_hash)
      Configuration.new(logger, config_hash) if configuration_validator.valid?(config_hash, Configuration::CURRENT_SCHEMA_VERSION, Configuration::STARTING_SCHEMA_VERSION)
    end
  end
end
