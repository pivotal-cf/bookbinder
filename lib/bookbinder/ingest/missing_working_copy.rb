module Bookbinder
  module Ingest
    class MissingWorkingCopy
      def initialize(source_repo_name)
        @source_repo_name = source_repo_name
      end

      def full_name
        @source_repo_name
      end

      def path
        Pathname("/this/doesnt/actually/exist/#{SecureRandom.uuid}")
      end

      def available?
        false
      end
    end
  end
end
