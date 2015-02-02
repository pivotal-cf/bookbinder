require_relative 'colorizer'
require_relative 'command_runner'
require_relative 'command_validator'
require_relative 'commands/bind'
require_relative 'commands/build_and_push_tarball'
require_relative 'commands/generate_pdf'
require_relative 'commands/help'
require_relative 'commands/version'
require_relative 'git_accessor'
require_relative 'local_dita_processor'
require_relative 'local_file_system_accessor'
require_relative 'middleman_runner'
require_relative 'repositories/command_repository'
require_relative 'spider'
require_relative 'terminal'
require_relative 'user_message_presenter'

module Bookbinder
  class Cli
    def run(args)
      command_name = args[0]
      command_arguments = args[1..-1]

      logger = BookbinderLogger.new
      yaml_loader = YAMLLoader.new
      local_file_system_accessor = LocalFileSystemAccessor.new
      configuration_validator = ConfigurationValidator.new(logger, local_file_system_accessor)
      configuration_fetcher = ConfigurationFetcher.new(logger, configuration_validator, yaml_loader)
      configuration_fetcher.set_config_file_path './config.yml'
      git_accessor = GitAccessor.new
      middleman_runner = MiddlemanRunner.new(logger, git_accessor)
      final_app_directory = File.absolute_path('final_app')
      spider = Spider.new(logger, app_dir: final_app_directory)
      server_director = ServerDirector.new(logger, directory: final_app_directory)
      sheller = Sheller.new(logger)
      colorizer = Colorizer.new
      user_message_presenter = UserMessagePresenter.new(colorizer)
      terminal = Terminal.new
      local_dita_processor = LocalDitaProcessor.new(sheller, configuration_fetcher)

      commands = Repositories::CommandRepository.new(logger,
                                                     configuration_fetcher,
                                                     git_accessor,
                                                     local_file_system_accessor,
                                                     middleman_runner,
                                                     spider,
                                                     final_app_directory,
                                                     server_director,
                                                     local_dita_processor)

      command_validator = CommandValidator.new(commands, commands.help.usage_message)
      command_runner = CommandRunner.new(logger, commands)
      command_name = command_name ? command_name : '--help'

      user_message = command_validator.validate(command_name)
      if user_message.escalation_type == EscalationType.error
        error_message = user_message_presenter.get_error(user_message)
        terminal.update(error_message)
        return 1
      elsif user_message.escalation_type == EscalationType.warn
        warning_message = user_message_presenter.get_warning(user_message)
        terminal.update(warning_message)
      end

      begin
        command_runner.run command_name, command_arguments

      rescue Commands::Bind::VersionUnsupportedError => e
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
