module Bookbinder
  module Deploy
    class Success
      attr_reader :reason

      def initialize(reason)
        @reason = reason
      end

      def success?
        true
      end
    end
  end
end

