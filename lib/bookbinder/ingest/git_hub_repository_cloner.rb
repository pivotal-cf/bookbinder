require_relative 'destination_directory'
require_relative 'working_copy'

module Bookbinder
  module Ingest
    class GitHubRepositoryCloner
      def initialize(version_control_system)
        @version_control_system = version_control_system
      end

      def call(from: nil,
               ref: "master",
               parent_dir: nil,
               dir_name: nil)
        dest_dir = DestinationDirectory.new(from, dir_name)
        copied_to = Pathname(parent_dir).join(dest_dir)
        version_control_system.clone(
          "git@github.com:#{from}",
          dest_dir,
          path: parent_dir,
          checkout: ref
        )
        WorkingCopy.new(
          copied_to: copied_to,
          directory: dir_name,
          full_name: from,
        )
      end

      private

      attr_reader :version_control_system
    end
  end
end
