require_relative 'cli_error'
require_relative 'local_dita_processor'
require_relative 'sheller'

module Bookbinder
  class CommandRunner
    def initialize(logger, commands)
      @logger = logger
      @commands = commands
    end

    def run(command_name, command_arguments)
      command = commands.detect { |known_command| known_command.command_name == command_name }
      command.run(command_arguments)
    rescue CliError::InvalidArguments
      logger.log command.usage
      1
    end

    private

    attr_reader :logger,
                :commands
  end
end

