require_relative 'destination_directory'

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

      attr_reader :copied_to, :full_name

      def available?
        !! copied_to
      end

      def directory
        DestinationDirectory.new(full_name, @directory).to_s
      end

      def path
        Pathname(@repo_dir).join(directory)
      end
    end
  end
end
