require_relative 'cli_error'
require 'ostruct'

module Bookbinder
  EscalationType = OpenStruct.new(error: 0, success: 1)

  class CommandValidator
    UserMessage = Struct.new(:message, :escalation_type)

    def initialize(commands, usage_text)
      @commands = commands
      @usage_text = usage_text
    end

    def validate! command_name
      command_type = "#{command_name}".match(/^--/) ? 'flag' : 'command'
      if commands.none? { |command| command.command_for?(command_name) }
        UserMessage.new "Unrecognized #{command_type} '#{command_name}'\n" + usage_text, EscalationType.error
      else
        UserMessage.new "Success", EscalationType.success
      end
    end

    private

    attr_reader :commands, :usage_text
  end
end

