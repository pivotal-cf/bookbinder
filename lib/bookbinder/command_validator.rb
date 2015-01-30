require_relative 'cli_error'

module Bookbinder
  class CommandValidator
    def initialize(commands, usage_text)
      @commands = commands
      @usage_text = usage_text
    end

    def validate! command_name
      command_type = "#{command_name}".match(/^--/) ? 'flag' : 'command'
      if commands.none? { |command| command.command_for?(command_name) }
        raise CliError::UnknownCommand.new "Unrecognized #{command_type} '#{command_name}'\n" + usage_text
      end
    end

    private

    attr_reader :commands, :usage_text
  end
end

