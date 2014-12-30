module Bookbinder
  class CommandRunner
    def initialize(configuration_fetcher, usage_messenger, logger, commands)
      @configuration_fetcher = configuration_fetcher
      @usage_messenger = usage_messenger
      @logger = logger
      @commands = commands
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

    attr_reader :logger, :usage_messenger, :commands

  end
end

