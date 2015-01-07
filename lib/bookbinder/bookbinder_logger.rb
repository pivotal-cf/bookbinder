require 'ansi'

class String
  include ANSI::Mixin
end

module Bookbinder
  class BookbinderLogger
    def log(message)
      puts message
    end

    def log_print(message)
      print message
    end

    def error(message)
      puts message.red
    end

    def success(message)
      puts message.green
    end

    def warn(message)
      puts message.yellow
    end

    def notify(message)
      puts message.blue
    end
  end
end
