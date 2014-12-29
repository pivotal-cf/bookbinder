require_relative 'local_file_system_accessor'

module Bookbinder
  class Cli
    class InvalidArguments < StandardError;
    end

    class CommandRouter
      def initialize(configuration_fetcher, usage_messenger, logger)
        @configuration_fetcher = configuration_fetcher
        @usage_messenger = usage_messenger
        @logger = logger
      end

      def route(command_name, command, command_arguments)
        if command_name && command_name.match(/^--/)
          flag = command_name[2..-1]
          if FLAGS.include? flag
            self.send flag
          else
            unrecognized_flag(flag)
          end
          0
        elsif command
          run_command(command, command_arguments)
        else
          unrecognized_command command_name
        end
      end

      private

      attr_reader :usage_messenger, :logger

      def version
        logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
      end

      def run_command(command, command_arguments)
        command.new(logger, @configuration_fetcher).run command_arguments
      rescue Publish::VersionUnsupportedError => e
        logger.error "config.yml at version '#{e.message}' has an unsupported API."
        1
      rescue Configuration::CredentialKeyError => e
        logger.error "#{e.message}, in credentials.yml"
        1
      rescue KeyError => e
        logger.error "#{e.message} from your configuration."
        1
      rescue Cli::InvalidArguments
        logger.log command.usage
        1
      rescue => e
        logger.error e.message
        1
      end

      def unrecognized_flag(name)
        logger.log "Unrecognized flag '--#{name}'"
        usage_messenger.print
      end

      def unrecognized_command(name)
        logger.log "Unrecognized command '#{name}'"
        usage_messenger.print
      end

    end

    FLAGS = %w(version)

    COMMANDS = [
        BuildAndPushTarball,
        GeneratePDF,
        Publish,
        PushLocalToStaging,
        PushToProd,
        RunPublishCI,
        Tag,
        UpdateLocalDocRepos,
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

      command_router = CommandRouter.new(configuration_fetcher, usage_messenger, logger)
      command_router.route command_name, command, command_arguments
    end

  end
end
