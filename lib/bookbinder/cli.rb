require_relative 'command_runner'
require_relative 'local_file_system_accessor'
require_relative 'commands/version'

module Bookbinder
  class Cli
    InvalidArguments = Class.new(StandardError)
    UnknownCommand = Class.new(StandardError)
    UnknownFlag = Class.new(StandardError)

    FLAGS = [
      Commands::Version
    ]

    COMMANDS = [
      Commands::BuildAndPushTarball,
      Commands::GeneratePDF,
      Commands::Publish,
      Commands::PushLocalToStaging,
      Commands::PushToProd,
      Commands::RunPublishCI,
      Commands::Tag,
      Commands::UpdateLocalDocRepos,
    ].freeze

    def run(args)
      command_name = args[0]
      command_arguments = args[1..-1]

      logger = BookbinderLogger.new
      yaml_loader = YAMLLoader.new
      local_file_system_accessor = LocalFileSystemAccessor.new
      configuration_validator = ConfigurationValidator.new(logger, local_file_system_accessor)
      configuration_fetcher = ConfigurationFetcher.new(logger, configuration_validator, yaml_loader)
      configuration_fetcher.set_config_file_path './config.yml'
      usage_messenger = UsageMessenger.new

      command_runner = CommandRunner.new(configuration_fetcher, usage_messenger, logger, COMMANDS + FLAGS)

      begin
        known_command_names = (COMMANDS + FLAGS).map(&:command_name)

        command_type = "#{command_name}".match(/^--/) ? 'flag' : 'command'
        if known_command_names.include?(command_name)
          command_runner.run command_name, command_arguments
        else
          logger.log "Unrecognized #{command_type} '#{command_name}'\n" +
            usage_messenger.construct_for(COMMANDS, FLAGS)
          1
        end

      rescue VersionUnsupportedError => e
        logger.error "config.yml at version '#{e.message}' has an unsupported API."
        1
      rescue Configuration::CredentialKeyError => e
        logger.error "#{e.message}, in credentials.yml"
        1
      rescue KeyError => e
        logger.error "#{e.message} from your configuration."
        1
      rescue Cli::UnknownCommand => e
        logger.log e.message
        1
      rescue Cli::UnknownFlag => e
        logger.log e.message
        1
      rescue => e
        logger.error e.message
        1
      end
    end
  end
end
