module Bookbinder
  module Ingest
    class MissingWorkingCopy
      def initialize(source_repo_name, source_dir)
        @source_repo_name = source_repo_name
        @source_dir= source_dir
      end

      def full_name
        @source_repo_name
      end

      def path
        Pathname(@source_dir)
      end

      def available?
        false
      end
    end
  end
end
