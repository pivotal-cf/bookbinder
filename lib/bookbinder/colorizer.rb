require 'ansi/code'
require 'ostruct'

module Bookbinder

  class Colorizer
    Color = OpenStruct.new(red: Proc.new { |msg| ANSI.red {msg} })

    def colorize(string, color)
      color.call string.to_s
    end
  end
end