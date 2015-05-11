module Bookbinder
  module Ingest
    class RepoIdentifier
      def initialize(input_identifier)
        @input_identifier = input_identifier
      end

      DEFAULT_VCS_PREFIX = 'git@github.com:'

      def to_str
        if input_identifier.include?(':')
          input_identifier
        else
          "#{DEFAULT_VCS_PREFIX}#{input_identifier}"
        end
      end

      def split(*args)
        input_identifier.split(*args)
      end

      alias :to_s :to_str

      def ==(other)
        to_str == other
      end

      alias :eql? :==

      def hash
        to_str.hash
      end

      private

      attr_reader :input_identifier
    end
  end
end
