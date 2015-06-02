require 'ansi/code'
require 'ostruct'

module Bookbinder
  class Colorizer
    Colors = OpenStruct.new(
      green: ->(msg) { ANSI.green {msg} },
      red: ->(msg) { ANSI.red {msg} },
      yellow: ->(msg) { ANSI.yellow {msg} },
    )

    def colorize(string, color)
      color.call string.to_s
    end
  end
end
