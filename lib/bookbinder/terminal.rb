require_relative 'command_validator'
require_relative 'colorizer'

module Bookbinder
  class Terminal
    def update(user_message)
      puts user_message
    end
  end
end
