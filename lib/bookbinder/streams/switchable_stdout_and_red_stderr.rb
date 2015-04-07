require_relative '../colorizer'

module Bookbinder
  module Streams
    class SwitchableStdoutAndRedStderr
      def initialize(options)
        @options = options
      end

      def to_h
        {
          out: options.include?('--verbose') ? $stdout : Sheller::DevNull.new,
          err: ColorizedStream.new(Colorizer::Colors.red, $stderr)
        }
      end

      private

      attr_reader :options
    end

    class ColorizedStream
      def initialize(color, stream)
        @color = color
        @stream = stream
        @colorizer = Colorizer.new
      end

      def puts(line)
        stream << colorizer.colorize(line, color)
      end

      private

      attr_reader :color, :colorizer, :stream
    end
  end
end
