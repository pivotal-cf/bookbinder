require_relative 'command_runner'
require_relative 'local_file_system_accessor'
require_relative 'command_validator'
require_relative 'git_accessor'
require_relative 'commands/build_and_push_tarball'
require_relative 'commands/generate_pdf'
require_relative 'commands/publish'
require_relative 'commands/version'
require_relative 'commands/help'
require_relative 'middleman_runner'
require_relative 'spider'

module Bookbinder
  class Cli
    FLAGS = [
      Commands::Version,
      Commands::Help
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
      usage_message = usage_messenger.construct_for(COMMANDS, FLAGS)
      command_validator = CommandValidator.new usage_messenger, COMMANDS + FLAGS, usage_message
      git_accessor = GitAccessor.new
      middleman_runner = MiddlemanRunner.new(logger, git_accessor)
      final_app_directory = File.absolute_path('final_app')
      spider = Spider.new(logger, app_dir: final_app_directory)
      server_director = ServerDirector.new(logger, directory: final_app_directory)

      command_runner = CommandRunner.new(configuration_fetcher,
                                         usage_message,
                                         logger,
                                         git_accessor,
                                         local_file_system_accessor,
                                         middleman_runner,
                                         spider,
                                         final_app_directory,
                                         server_director,
                                         COMMANDS + FLAGS)

      begin
        command_name ? command_validator.validate!(command_name) : command_name = '--help'

        command_runner.run command_name, command_arguments

      rescue Commands::Publish::VersionUnsupportedError => e
        logger.error "config.yml at version '#{e.message}' has an unsupported API."
        1
      rescue Configuration::CredentialKeyError => e
        logger.error "#{e.message}, in credentials.yml"
        1
      rescue KeyError => e
        logger.error "#{e.message} from your configuration."
        1
      rescue CliError::UnknownCommand => e
        logger.log e.message
        1
      rescue RuntimeError => e
        logger.error e.message
        1
      end
    end
  end
end
