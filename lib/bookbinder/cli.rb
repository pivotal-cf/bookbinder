require_relative 'command_router'
require_relative 'local_file_system_accessor'

module Bookbinder
  class Cli
    class InvalidArguments < StandardError;
    end

    FLAGS = %w(version)

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
      command = COMMANDS.detect { |known_command| known_command.command_name == command_name }
      command_arguments = args[1..-1]

      logger = BookbinderLogger.new
      yaml_loader = YAMLLoader.new
      local_file_system_accessor = LocalFileSystemAccessor.new
      configuration_validator = ConfigurationValidator.new(logger, local_file_system_accessor)
      configuration_fetcher = ConfigurationFetcher.new(logger, configuration_validator, yaml_loader)
      configuration_fetcher.set_config_file_path './config.yml'

      usage_messenger = UsageMessenger.new(logger, COMMANDS, FLAGS)

      command_router = CommandRouter.new(configuration_fetcher, usage_messenger, logger, FLAGS)
      command_router.route command_name, command, command_arguments
    end

  end
end
