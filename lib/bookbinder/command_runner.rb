module Bookbinder
  class CommandRunner
    class VersionFlag
      def initialize(logger)
        @logger = logger
      end

      def run(*)
        logger.log "bookbinder #{Gem::Specification::load(File.join GEM_ROOT, "bookbinder.gemspec").version}"
        0
      end

      private

      attr_reader :logger
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

    def initialize(configuration_fetcher, usage_messenger, logger)
      @configuration_fetcher = configuration_fetcher
      @usage_messenger = usage_messenger
      @logger = logger
    end

    def run(command_name, command_arguments)
      command = COMMANDS.detect { |known_command| known_command.command_name == command_name }
      if command_name && command_name.match(/^--/)
        flag = command_name[2..-1]
        if FLAGS.include?(flag)
          "Bookbinder::CommandRunner::#{flag.classify}Flag".constantize.new(logger).run
        else
          unrecognized_flag(flag)
        end
      elsif command
        begin
          command.new(logger, @configuration_fetcher).run command_arguments
        rescue Cli::InvalidArguments
          logger.log command.usage
          1
        end
      else
        unrecognized_command command_name
      end
    end

    private

    attr_reader :logger, :usage_messenger

    def unrecognized_flag(name)
      raise Cli::UnknownFlag.new "Unrecognized flag '--#{name}'\n" +
                                     usage_messenger.construct_for(COMMANDS, FLAGS)
    end

    def unrecognized_command(name)
      raise Cli::UnknownCommand.new "Unrecognized command '#{name}'\n" +
                                        usage_messenger.construct_for(COMMANDS, FLAGS)
    end
  end
end

