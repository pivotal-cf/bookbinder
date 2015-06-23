module Bookbinder
  module Ingest
    class UpdateFailure
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
