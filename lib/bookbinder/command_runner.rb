module Bookbinder
  class CommandRunner
    class VersionFlag

      def self.command_name
        '--version'
      end

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

    def initialize(configuration_fetcher, usage_messenger, logger, commands, flags)
      @configuration_fetcher = configuration_fetcher
      @usage_messenger = usage_messenger
      @logger = logger
      @commands = commands
      @flags = flags
    end

    def run(command_name, command_arguments)
      command = commands.detect { |known_command| known_command.command_name == command_name }
      begin
        command.new(logger, @configuration_fetcher).run command_arguments
      rescue Cli::InvalidArguments
        logger.log command.usage
        1
      end
    end

    private

    attr_reader :logger, :usage_messenger, :flags, :commands

  end
end

