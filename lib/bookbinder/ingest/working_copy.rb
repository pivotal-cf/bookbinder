module Bookbinder
  module Ingest
    class WorkingCopy
      def initialize(copied: nil,
                     copied_to: nil,
                     directory: nil,
                     full_name: nil)
        @copied = copied
        @copied_to = copied_to
        @directory = directory
        @full_name = full_name
      end

      attr_reader :copied_to, :directory, :full_name

      def copied?
        @copied
      end
    end
  end
end
