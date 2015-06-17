require_relative 'errors/cli_error'

module Bookbinder
  class CommandRunner
    def initialize(logger, commands)
      @logger = logger
      @commands = commands
    end

    def run(command_name, command_arguments)
      command = commands.detect { |known_command| known_command.command_for?(command_name) }
      command.run(command_arguments)
    rescue CliError::InvalidArguments
      logger.log ["bookbinder #{command.usage[0]}", command.usage[1]]
      1
    end

    private

    attr_reader :logger, :commands
  end
end

