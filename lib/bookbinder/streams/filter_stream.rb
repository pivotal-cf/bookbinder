module Bookbinder
  module Streams
    class FilterStream
      def initialize(matcher_regex, stream)
        @matcher_regex = matcher_regex
        @stream = stream
      end

      def puts(line)
        stream.puts(line) if line.match(matcher_regex)
      end

      def <<(line)
        stream << line if line.match(matcher_regex)
      end

      private

      attr_reader :matcher_regex, :stream
    end
  end
end
