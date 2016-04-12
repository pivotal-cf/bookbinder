require_relative 'colorizer'

module Bookbinder
  class Terminal
    def initialize(colorizer)
      @colorizer = colorizer
    end

    def update(user_message)
      if user_message.error?
        error_message = @colorizer.colorize(user_message.message, Colorizer::Colors.red)
        $stderr.puts error_message
      elsif user_message.warn?
        warning_message = @colorizer.colorize(user_message.message, Colorizer::Colors.yellow)
        puts warning_message
      end
    end
  end
end
