require 'ansi/code'
require 'ostruct'

module Bookbinder
  class Colorizer
    Colors = OpenStruct.new(red: Proc.new { |msg| ANSI.red {msg} },
                            yellow: Proc.new { |msg| ANSI.yellow {msg} })

    def colorize(string, color)
      color.call string.to_s
    end
  end
end
