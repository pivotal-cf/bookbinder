require_relative 'command_validator'
require_relative 'colorizer'

module Bookbinder
  class Terminal

    def initialize(colorizer)
      @colorizer = colorizer
    end

    def update(user_message)
      if user_message.escalation_type == EscalationType.error
        puts @colorizer.colorize(user_message.message, Colorizer::Color.red)
      end
    end

    private

    attr_reader :colorizer
  end
end
