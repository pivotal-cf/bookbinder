module Bookbinder
  module Ingest
    class RepoIdentifier
      DEFAULT_VCS_PREFIX = 'git@github.com:'

      def initialize(input_identifier)
        @input_identifier = input_identifier
      end

      def to_str
        if input_identifier.nil?
          ""
        elsif input_identifier.include?(':') || input_identifier.match(/^\//)
          input_identifier
        else
          "#{DEFAULT_VCS_PREFIX}#{input_identifier}"
        end
      end

      alias :to_s :to_str

      def inspect
        %Q("#{to_s}")
      end

      def split(*args)
        input_identifier.split(*args)
      end

      def hash
        to_str.hash
      end

      def ==(other)
        to_str == other
      end

      alias :eql? :==

      private

      attr_reader :input_identifier
    end
  end
end
