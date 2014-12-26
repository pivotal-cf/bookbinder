require_relative 'local_file_system_accessor'

module Bookbinder
  class Cli
    class InvalidArguments < StandardError;
    end

    class CommandRouter
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

      def version
        logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
      end

      def run_command(command, command_arguments)
        yaml_loader = YAMLLoader.new
        local_file_system_accessor = LocalFileSystemAccessor.new
        configuration_validator = ConfigurationValidator.new(logger, local_file_system_accessor)
        @configuration_fetcher = ConfigurationFetcher.new(logger, configuration_validator, yaml_loader)
        @configuration_fetcher.set_config_file_path './config.yml'
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
        logger.log usage_message.command(command)
        1
      rescue => e
        logger.error e.message
        1
      end

      def unrecognized_flag(name)
        logger.log "Unrecognized flag '--#{name}'"
        usage_message.print
      end

      def unrecognized_command(name)
        logger.log "Unrecognized command '#{name}'"

        usage_message.print
      end

      def usage_message
        UsageMessenger.new(logger, COMMAND_TO_CLASS_MAPPING, FLAGS)
      end

      def logger
        @logger ||= BookbinderLogger.new
      end
    end

    FLAGS = %w(version)

    # breaking this command => class naming convention will break usage_messages!
    COMMAND_TO_CLASS_MAPPING = {
        'publish' => Publish,
        'build_and_push_tarball' => BuildAndPushTarball,
        'push_local_to_staging' => PushLocalToStaging,
        'push_to_prod' => PushToProd,
        'run_publish_ci' => RunPublishCI,
        'update_local_doc_repos' => UpdateLocalDocRepos,
        'tag' => Tag,
        'generate_pdf' => GeneratePDF
    }.freeze

    def run(args)
      command_name = args[0]
      command = COMMAND_TO_CLASS_MAPPING[command_name]
      command_arguments = args[1..-1]

      command_router = CommandRouter.new
      command_router.route command_name, command, command_arguments
    end
  end
end
