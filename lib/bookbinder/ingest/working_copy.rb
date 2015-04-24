module Bookbinder
  module Ingest
    class WorkingCopy
      def initialize(repo_dir: nil,
                     copied_to: nil,
                     directory: nil,
                     full_name: nil)
        @repo_dir = repo_dir
        @copied_to = copied_to
        @directory = directory
        @full_name = full_name
      end

      attr_reader :copied_to, :directory, :full_name

      def copied?
        ! copied_to.nil?
      end

      def directory
        @directory || short_name
      end

      def path
        Pathname(@repo_dir).join(short_name)
      end

      private

      def short_name
        full_name.split('/')[1]
      end
    end
  end
end
