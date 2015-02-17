require_relative 'colorizer'

module Bookbinder
  class UserMessagePresenter
    def initialize(colorizer)
      @colorizer = colorizer
    end

    def get_error(user_message)
      colorizer.colorize(user_message.message, Colorizer::Colors.red)
    end

    def get_warning(user_message)
      colorizer.colorize(user_message.message, Colorizer::Colors.yellow)
    end

    private

    attr_reader :colorizer
  end
end
