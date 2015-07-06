module Bookbinder
  module Deploy
    class Failure
      attr_reader :reason

      def initialize(reason)
        @reason = reason
      end

      def success?
        false
      end
    end
  end
end
