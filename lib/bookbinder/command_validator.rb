require_relative 'cli_error'
require 'ostruct'
require_relative 'user_message'

module Bookbinder
  class CommandValidator
    def initialize(commands, usage_text)
      @commands = commands
      @usage_text = usage_text
    end

    def validate command_name
      command_type = "#{command_name}".match(/^--/) ? 'flag' : 'command'
      if commands.none? { |command| command.command_for?(command_name) }
        UserMessage.new "Unrecognized #{command_type} '#{command_name}'\n" + usage_text, EscalationType.error
      elsif command = commands.find { |command| (command.respond_to? :deprecated_command_for?) &&
                                                                        (command.deprecated_command_for? command_name) }
        UserMessage.new "Use of #{command_name} is deprecated. " +
                            "The preferred usage is below: \n#{command.usage}",
                        EscalationType.warn
      else
        UserMessage.new "Success", EscalationType.success
      end
    end

    private

    attr_reader :commands, :usage_text
  end
end

