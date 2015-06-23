require_relative '../colorizer'

module Bookbinder
  module Streams
    class ColorizedStream
      def initialize(color, stream)
        @color = color
        @stream = stream
        @colorizer = Colorizer.new
      end

      def puts(line)
        stream.puts(colorizer.colorize(line, color))
      end

      def <<(text)
        stream << colorizer.colorize(text, color)
      end

      private

      attr_reader :color, :colorizer, :stream
    end
  end
end
